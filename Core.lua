-- Core: namespace, saved variables, events, combat queue, chat output.
local ADDON, ns = ...

-- the addon namespace, for companion addons
DeckForever = ns
ns.name = ADDON
ns.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "dev"

local DB_VERSION = 1

local DEFAULTS = {
	version = DB_VERSION,
	promptedOnce = false,
	options = {
		syncRaid = true,       -- also set the RAID/raidGraphics twin of every CVar
		reminder = false,      -- session reminder for the beta memory leak
		reminderMinutes = 90,
		reminderSagPct = 25,
		minimap = { hide = false, angle = 225 },
		window = { tab = "presets", scale = 1.15 }, -- point is saved when the window is dragged
	},
	-- activePreset, snapshot, mark, lastApply, lastCheck, lastDiff are created on demand
}

local function MergeDefaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			MergeDefaults(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

function ns.InitDB()
	if type(DeckForeverDB) ~= "table" then DeckForeverDB = {} end
	MergeDefaults(DeckForeverDB, DEFAULTS)
	DeckForeverDB.version = DB_VERSION
	ns.DB = DeckForeverDB
end

-- Chat output -----------------------------------------------------------------

local PREFIX = "|cff33ccffDeckForever|r: "

function ns.Print(fmt, ...)
	local msg = select("#", ...) > 0 and fmt:format(...) or fmt
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
	else
		print(PREFIX .. msg)
	end
end

-- Events -----------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		eventFrame:RegisterEvent(event)
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do fn(...) end
end)

-- Internal callbacks so the UI can refresh when state changes.
local listeners = {}

function ns.Listen(fn) table.insert(listeners, fn) end

function ns.Changed()
	for _, fn in ipairs(listeners) do fn() end
end

-- Combat queue -----------------------------------------------------------------
-- Some CVars are refused in combat, so every write waits for combat to end.
-- Jobs with the same key replace each other: the last requested preset wins.

local queue = {}

function ns.RunWhenSafe(key, fn)
	if not InCombatLockdown() then
		fn()
		return true
	end
	for i, job in ipairs(queue) do
		if job.key == key then table.remove(queue, i) break end
	end
	table.insert(queue, { key = key, fn = fn })
	ns.Print("In combat: will apply when combat ends.")
	ns.Changed()
	return false
end

function ns.HasQueued() return #queue > 0 end

ns.On("PLAYER_REGEN_ENABLED", function()
	local jobs = queue
	queue = {}
	for _, job in ipairs(jobs) do job.fn() end
end)

ns.On("ADDON_LOADED", function(name)
	if name == ADDON then ns.InitDB() end
end)
