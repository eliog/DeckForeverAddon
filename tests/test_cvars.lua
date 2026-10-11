local mock = require("wowmock")

test("TOC lists every Lua file in the addon and they all load", function()
	local w = mock.new()
	local listed = {}
	for _, f in ipairs(w.files) do listed[f] = true end
	local p = io.popen('cd "' .. mock.ROOT .. '" && git ls-files "*.lua" | grep -v "^tests/"')
	for f in p:lines() do ok(listed[f], f .. " is not in DeckForever.toc") end
	p:close()
end)

test("addon creates no globals besides its saved variables, slash command and named frames", function()
	local before = {}
	for k in pairs(_G) do before[k] = true end
	local w = mock.new()
	w:login()
	w:slash("")
	w.ns.ShowPrompt()
	w.ns.ShowEditor()
	w.ns.ShowGuide()
	w.ns.ToggleMenu()
	w:slash("apply performance")
	local allowed = {
		DeckForeverDB = true, SLASH_DECKFOREVER1 = true, DeckForever = true,
		DeckForeverWindow = true, DeckForeverPrompt = true, DeckForeverKeep = true,
		DeckForeverMenu = true, DeckForeverMinimapButton = true,
		DeckForeverFocus = true,
	}
	for k in pairs(_G) do
		if not before[k] then ok(allowed[k], "unexpected global " .. tostring(k)) end
	end
end)

test("FormatValue writes values the way the client stores them", function()
	local ns = mock.new().ns
	eq(ns.FormatValue(60), "60")
	eq(ns.FormatValue(1.0), "1")
	eq(ns.FormatValue(0.85), "0.85")
	eq(ns.FormatValue(2.6), "2.6")
	eq(ns.FormatValue("D3D12"), "D3D12")
end)

test("ValuesEqual treats numeric spellings as equal", function()
	local ns = mock.new().ns
	ok(ns.ValuesEqual("1.000000", 1))
	ok(ns.ValuesEqual("0.85", 0.85))
	ok(not ns.ValuesEqual("2", 3))
	ok(ns.ValuesEqual("d3d12", "D3D12"))
	ok(not ns.ValuesEqual(nil, "1"))
end)

test("every CVar with a twin maps to a twin present in the Forever Config.wtf", function()
	local w = mock.new()
	for name, m in pairs(w.ns.CVarMeta) do
		if m.twin and m.seen then
			ok(w:cvar(m.twin) ~= nil, ("twin %s of %s not in Config.wtf"):format(m.twin, name))
		end
	end
end)

test("every CVar marked seen is in the Forever Config.wtf", function()
	local w = mock.new()
	for name, m in pairs(w.ns.CVarMeta) do
		if m.seen then ok(w:cvar(name) ~= nil, name .. " marked seen but not in Config.wtf") end
	end
end)

test("every preset value is within its declared range and uses a known CVar", function()
	local ns = mock.new().ns
	for _, key in ipairs(ns.Presets.order) do
		local p = ns.Presets[key]
		for name, v in pairs(p.values) do
			ok(ns.CVarMeta[name], key .. ": no metadata for " .. name)
			local good, why = ns.InRange(name, v)
			ok(good, ("%s: %s=%s %s"):format(key, name, tostring(v), tostring(why)))
		end
		for name in pairs(p.raid) do
			ok(p.values[name] ~= nil, key .. ": raid override without a normal value: " .. name)
		end
	end
end)

test("WriteCVars skips unknown and locked CVars and reports them", function()
	local w = mock.new({ missing = { "maxFPSLoading" }, locked = { "vsync" } })
	w:login()
	local res = w.ns.WriteCVars({
		{ name = "maxFPSLoading", value = 30 },
		{ name = "vsync", value = 0 },
		{ name = "maxFPS", value = 60 },
	})
	eq(#res.skipped, 2)
	eq(res.skipped[1].reason, "unknown to this client")
	eq(res.skipped[2].reason, "locked")
	eq(#res.changed, 1)
	eq(w:cvar("maxFPS"), "60")
	eq(w:cvar("vsync"), "1")
end)

test("WriteCVars refuses out-of-range values unless told not to check", function()
	local w = mock.new()
	w:login()
	local res = w.ns.WriteCVars({ { name = "RenderScale", value = 0.2 } })
	eq(#res.skipped, 1)
	eq(w:cvar("RenderScale"), "1")
	res = w.ns.WriteCVars({ { name = "RenderScale", value = "0.2" } }, { noRangeCheck = true })
	eq(#res.changed, 1)
end)

test("MSAAQuality reading back as samples,coverage counts as set", function()
	local w = mock.new()
	w:login()
	eq(w:cvar("MSAAQuality"), "0,0")
	ok(w.ns.ValuesEqual("0,0", 0))
	ok(not w.ns.ValuesEqual("2,0", 0))
	local res = w.ns.WriteCVars({ { name = "MSAAQuality", value = 0 } })
	eq(#res.unchanged, 1, "0,0 already equals 0")
	res = w.ns.WriteCVars({ { name = "MSAAQuality", value = 2 } })
	eq(#res.changed, 1)
	eq(#res.failed, 0)
end)

test("secure CVars are skipped and a throwing SetCVar is a failure, not an error", function()
	local w = mock.new({ secure = { "vsync" }, throws = { "maxFPS" } })
	w:login()
	local res = w.ns.WriteCVars({
		{ name = "vsync", value = 0 },
		{ name = "maxFPS", value = 60 },
		{ name = "maxFPSBk", value = 20 },
	})
	eq(res.skipped[1].name, "vsync")
	eq(res.skipped[1].reason, "locked")
	eq(res.failed[1].name, "maxFPS")
	eq(res.changed[1], "maxFPSBk", "the rest still applies")
end)

test("applying prints reload/restart notes for CVars that need them", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply battery")
	contains(w:chatText(), "Compute Effects frees its frame time fully only after /reload")
	local _, n = w:chatText():gsub("Compute Effects frees", "")
	eq(n, 1, "once, not once per twin")
end)
