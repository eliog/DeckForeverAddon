-- Minimal World of Warcraft API mock: enough to load the addon from its TOC and drive it.
-- The CVar store starts from the Forever client's own first-run Config.wtf.
local M = {}

local ROOT = (debug.getinfo(1, "S").source:match("^@(.*)tests/wowmock%.lua$")) or "./"
M.ROOT = ROOT

local function ReadConfigWtf(path)
	local t = {}
	for line in io.lines(path) do
		local name, value = line:gsub("\r$", ""):match('^SET (%S+) "(.*)"$')
		if name then t[name] = value end
	end
	return t
end

-- CVars from warcraft.wiki.gg defaults that are not in the first-run file.
local WIKI_DEFAULTS = {
	useTargetFPS = "1", targetFPS = "60", useMaxFPS = "0", maxFPS = "144",
	useMaxFPSBk = "1", maxFPSBk = "30", maxFPSLoading = "30",
	RenderScale = "1", ResampleQuality = "3", ffxAntiAliasingMode = "0", MSAAQuality = "0,0", -- MSAA reads back as "samples,coverage"
	physicsLevel = "1", useUiScale = "0", uiScale = "1", cameraDistanceMaxZoomFactor = "1.9",
	GamePadEnable = "1", InputDeviceInterfaceStyle = "0", -- as seen in Forever
}

-- Index CVars rewrite raw ones, like the client does. Used to test write order.
local SIDE_EFFECTS = {
	graphicsparticledensity = function(store, v)
		local map = { [0] = "10", "30", "50", "70", "100", "100" }
		store:raw("particleDensity", map[tonumber(v)] or "50")
	end,
	msaaquality = function(store, v)
		store:raw("MSAAQuality", v .. ",0")
	end,
	graphicsshadowquality = function(store, v)
		store:raw("shadowMode", v)
		store:raw("shadowNumCascades", tonumber(v) >= 2 and "3" or "1")
	end,
}

local function NewStore(opts)
	local store = { data = {}, sets = {} }
	function store:define(name, value, default)
		self.data[name:lower()] = { name = name, value = value, default = default or value }
	end
	function store:raw(name, value)
		local e = self.data[name:lower()]
		if e then e.value = value end
	end
	local initial = ReadConfigWtf(ROOT .. "tests/fixtures/config-forever-16001-first-run.wtf")
	for k, v in pairs(WIKI_DEFAULTS) do initial[k] = v end
	for _, k in ipairs(opts.missing or {}) do initial[k] = nil end
	for k, v in pairs(opts.hidden or {}) do initial[k] = v end
	for k, v in pairs(initial) do store:define(k, v) end
	store.locked, store.secure = {}, {}
	for _, k in ipairs(opts.locked or {}) do store.locked[k:lower()] = true end
	for _, k in ipairs(opts.secure or {}) do store.secure[k:lower()] = true end
	store.throws = {}
	for _, k in ipairs(opts.throws or {}) do store.throws[k:lower()] = true end
	return store
end

-- Frames ---------------------------------------------------------------------

local function NewFrame(world, name)
	local f = { scripts = {}, events = {}, shown = true } -- frames start shown, like the client
	local stub
	stub = setmetatable(f, { __index = function(_, k)
		return function() return stub end
	end })
	function f:SetScript(s, fn) self.scripts[s] = fn end
	function f:GetScript(s) return self.scripts[s] end
	function f:RegisterEvent(e) self.events[e] = true end
	function f:UnregisterEvent(e) self.events[e] = nil end
	function f:Show()
		self.shown = true
		if self.scripts.OnShow then self.scripts.OnShow(self) end
	end
	function f:Hide()
		local was = self.shown
		self.shown = false
		if was and self.scripts.OnHide then self.scripts.OnHide(self) end
	end
	function f:IsShown() return self.shown end
	function f:SetText(t) self.text = t end
	function f:SetScale(s) self.scale = s end
	function f:GetScale() return rawget(self, "scale") or 1 end
	function f:GetText() return self.text end
	function f:SetEnabled(e) self.enabled = e end
	function f:IsEnabled() return self.enabled ~= false end
	function f:SetShown(s) if s then self:Show() else self:Hide() end end
	function f:SetSize(w, h) self.width, self.height = w, h end
	function f:GetWidth() return rawget(self, "width") or 140 end
	function f:GetHeight() return rawget(self, "height") or 140 end
	function f:GetCenter() return 500, 400 end
	function f:GetParent() return rawget(self, "parent") end
	function f:GetEffectiveScale() return 1 end
	function f:CreateTexture() return NewFrame(world) end
	function f:CreateFontString() return NewFrame(world) end
	function f:Click(mouse)
		if self.scripts.OnClick then self.scripts.OnClick(self, mouse or "LeftButton") end
	end
	table.insert(world.frames, f)
	if name then
		_G[name] = f
		M.named[name] = true
	end
	return f
end

M.named = {}

-- World ------------------------------------------------------------------------

-- Creates fresh globals and loads the addon. opts: missing = {cvars}, locked = {cvars},
-- screen = {w, h}, savedVariables = table, combat = bool.
function M.new(opts)
	opts = opts or {}
	local world = {
		frames = {}, chat = {}, timers = {}, now = 0, fps = 60,
		combat = opts.combat or false,
		screen = opts.screen or { 1280, 800 },
		store = NewStore(opts),
	}
	local store = world.store

	for name in pairs(M.named) do _G[name] = nil end
	_G.DeckForeverDB = opts.savedVariables
	_G.SLASH_DECKFOREVER1 = nil
	_G.SlashCmdList = {}
	_G.UISpecialFrames = {}
	_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) table.insert(world.chat, msg) end }
	_G.CreateFrame = function(_, name, parent)
		local f = NewFrame(world, name)
		f.parent = parent
		return f
	end
	_G.UIParent = NewFrame(world)
	_G.Minimap = NewFrame(world)
	_G.GameTooltip = NewFrame(world)
	world.cursor = { 0, 0 }
	_G.GetCursorPosition = function() return world.cursor[1], world.cursor[2] end
	world.reloads = 0
	_G.ReloadUI = function() world.reloads = world.reloads + 1 end
	_G.time = os.time
	_G.date = os.date
	_G.InCinematic = function() return world.cinematic or false end
	_G.IsPlayerMoving = function() return world.moving or false end
	_G.GetRealZoneText = function() return world.zone or "Tirisfal Glades" end
	_G.InCombatLockdown = function() return world.combat end
	_G.GetFramerate = function() return world.fps end
	_G.GetPhysicalScreenSize = function() return world.screen[1], world.screen[2] end
	_G.GetBuildInfo = function() return "1.60.1", "70009", "Oct 1 2026", 16001 end
	_G.C_AddOns = { GetAddOnMetadata = function() return "test" end }
	_G.Enum = { ConsoleCommandType = { Cvar = 0, Command = 1 } }

	_G.C_CVar = {
		GetCVar = function(name)
			local e = store.data[name:lower()]
			return e and e.value
		end,
		GetCVarDefault = function(name)
			local e = store.data[name:lower()]
			return e and e.default
		end,
		GetCVarInfo = function(name)
			local e = store.data[name:lower()]
			if not e then return nil end
			local locked = store.locked[name:lower()] or false
			local secure = store.secure[name:lower()] or false
			return e.value, e.default, false, false, locked, secure, false
		end,
		SetCVar = function(name, value)
			local key = name:lower()
			local e = store.data[key]
			if not e or store.locked[key] then return false end
			if store.secure[key] or store.throws[key] then error("cannot set " .. name) end
			assert(not world.combat, "SetCVar called in combat: " .. name)
			assert(type(value) == "string", "SetCVar value should be a string: " .. name)
			e.value = value
			table.insert(store.sets, e.name)
			if SIDE_EFFECTS[key] then SIDE_EFFECTS[key](store, value) end
			return true
		end,
	}
	local function AllCommands()
		local list = {}
		for _, e in pairs(store.data) do
			-- the global variant reports a type the old filter did not expect
			list[#list + 1] = { command = e.name, commandType = opts.enum == "global" and 5 or 0 }
		end
		list[#list + 1] = { command = "reloadui", commandType = 1 }
		return list
	end
	_G.C_Console = (opts.enum == nil) and { GetAllCommands = AllCommands } or {}
	_G.ConsoleGetAllCommands = (opts.enum == "global") and AllCommands or nil
	_G.C_Timer = {
		After = function(sec, fn)
			table.insert(world.timers, { at = world.now + sec, fn = fn })
		end,
		NewTicker = function(sec, fn)
			local t = { at = world.now + sec, every = sec, fn = fn }
			table.insert(world.timers, t)
			return { Cancel = function() t.cancelled = true end }
		end,
	}

	-- load files in TOC order, the way the client does
	local ns = {}
	local files = {}
	for line in io.lines(ROOT .. "DeckForever.toc") do
		if line:match("%S") and not line:match("^%s*#") then
			files[#files + 1] = (line:gsub("\\", "/"):gsub("%s+$", ""))
		end
	end
	world.files = files
	for _, file in ipairs(files) do
		local chunk = assert(loadfile(ROOT .. file))
		chunk("DeckForever", ns)
	end
	world.ns = ns
	-- opts.addons = { { name =, toc = path } }: other addons that load after this one
	for _, a in ipairs(opts.addons or {}) do
		local dir = a.toc:match("^(.*)/[^/]+$") .. "/"
		for line in io.lines(a.toc) do
			if line:match("%S") and not line:match("^%s*#") then
				local chunk = assert(loadfile(dir .. (line:gsub("\\", "/"):gsub("%s+$", ""))))
				chunk(a.name, {})
			end
		end
	end

	function world:fire(event, ...)
		for _, f in ipairs(self.frames) do
			if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
		end
	end

	function world:advance(seconds)
		local target = self.now + seconds
		while true do
			local nextT
			for _, t in ipairs(self.timers) do
				if not t.cancelled and not t.done and t.at <= target and (not nextT or t.at < nextT.at) then nextT = t end
			end
			if not nextT then break end
			self.now = nextT.at
			if nextT.every then nextT.at = nextT.at + nextT.every else nextT.done = true end
			nextT.fn()
		end
		self.now = target
	end

	function world:login()
		self:fire("ADDON_LOADED", "DeckForever")
		self:fire("PLAYER_LOGIN")
		self:fire("PLAYER_ENTERING_WORLD", true, false)
	end

	function world:slash(msg) _G.SlashCmdList.DECKFOREVER(msg) end
	function world:cvar(name) return _G.C_CVar.GetCVar(name) end
	function world:setCombat(on)
		self.combat = on
		self:fire(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
	end
	function world:chatText() return table.concat(self.chat, "\n") end
	function world:clearChat() self.chat = {} end
	function world:frame(name) return _G[name] end

	return world
end

return M
