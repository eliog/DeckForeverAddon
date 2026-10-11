local mock = require("wowmock")

local function AllValues(w)
	local t = {}
	for k, e in pairs(w.store.data) do t[k] = e.value end
	return t
end

test("restore puts back exactly the settings from before the first preset", function()
	local w = mock.new()
	w:login()
	local before = AllValues(w)
	w:slash("apply performance")
	w:slash("apply battery")
	w:slash("apply quality")
	w:slash("restore")
	local after = AllValues(w)
	for k, v in pairs(before) do eq(after[k], v, k) end
	eq(w.ns.DB.snapshot, nil, "snapshot cleared after a clean restore")
	eq(w.ns.DB.activePreset, nil)
end)

test("raw CVars rewritten by index CVars are restored too", function()
	local w = mock.new()
	w:login()
	eq(w:cvar("shadowNumCascades"), "3")
	w:slash("apply battery") -- graphicsShadowQuality 0 makes the client set shadowNumCascades 1
	eq(w:cvar("shadowNumCascades"), "1")
	w:slash("restore")
	eq(w:cvar("shadowNumCascades"), "3")
end)

test("snapshot is taken once, on the first apply only", function()
	local w = mock.new()
	w:login()
	w:slash("apply performance")
	local snap = w.ns.DB.snapshot
	eq(snap.cvars.maxFPS, "144")
	w:slash("apply battery")
	ok(w.ns.DB.snapshot == snap, "second apply must not replace the snapshot")
	eq(w.ns.DB.snapshot.cvars.maxFPS, "144")
end)

test("snapshot survives a reload through SavedVariables", function()
	local w = mock.new()
	w:login()
	w:slash("apply performance")
	local saved = DeckForeverDB
	local w2 = mock.new({ savedVariables = saved })
	-- the second client starts with the performance values already in place
	for k, e in pairs(w.store.data) do w2.store.data[k].value = e.value end
	w2:login()
	ok(w2.ns.HasSnapshot())
	w2:slash("restore")
	eq(w2:cvar("maxFPS"), "144")
end)

test("restore without a snapshot says so and writes nothing", function()
	local w = mock.new()
	w:login()
	w:slash("restore")
	contains(w:chatText(), "Nothing to restore")
	eq(#w.store.sets, 0)
end)

test("restore keeps the snapshot if a CVar cannot be put back", function()
	local w = mock.new()
	w:login()
	w:slash("apply performance")
	w.store.locked["maxfps"] = true
	w:slash("restore")
	ok(w.ns.DB.snapshot ~= nil, "snapshot kept for a retry")
	contains(w:chatText(), "kept so you can retry")
	w.store.locked["maxfps"] = nil
	w:slash("restore")
	eq(w:cvar("maxFPS"), "144")
	eq(w.ns.DB.snapshot, nil)
end)

test("restore in combat waits for combat to end", function()
	local w = mock.new()
	w:login()
	w:slash("apply performance")
	w:setCombat(true)
	w:slash("restore")
	eq(w:cvar("maxFPS"), "60")
	w:setCombat(false)
	eq(w:cvar("maxFPS"), "144")
end)

test("saved variables get defaults and keep existing options", function()
	local w = mock.new({ savedVariables = { options = { syncRaid = false } } })
	w:login()
	eq(w.ns.DB.options.syncRaid, false)
	eq(w.ns.DB.options.reminder, false)
	eq(w.ns.DB.version, 1)
end)
