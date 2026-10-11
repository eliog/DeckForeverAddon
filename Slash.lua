-- Slash: /deckforever
local _, ns = ...

local HELP = {
	"/deckforever - open the DeckForever window",
	"/deckforever apply battery|balanced|performance|quality",
	"/deckforever restore - put back your settings from before the first preset",
	"/deckforever preview <preset> - list what a preset would change",
	"/deckforever fps - current frame rate and cap",
	"/deckforever status - active preset, snapshot and options",
	"/deckforever raid on|off - also set raid/battleground twins (default on)",
	"/deckforever reminder on|off|<minutes> - relog reminder when fps sags",
	"/deckforever prompt - show the first-login offer again",
	"/deckforever customize [preset] - change the settings a preset applies",
	"/deckforever deck [preset] - Steam Deck Quick Access settings for a preset",
	"/deckforever set <preset> <cvar> <value> - override one preset setting",
	"/deckforever reset <preset> [cvar] - back to the built-in preset values",
	"/deckforever minimap on|off - show or hide the minimap button",
	"/deckforever uiscale <0.5-1.0>|default - size of the game's interface (the game locks its own setting)",
}

local function OnOff(v)
	return v and "on" or "off"
end

local commands = {}
-- open to companion addons
ns.SlashCommands, ns.SlashHelp = commands, HELP

commands.apply = function(arg) ns.ApplyPreset(arg) end
commands.restore = function() ns.RestoreSnapshot() end
commands.prompt = function() ns.ShowPrompt() end
commands.show = function() ns.ShowPanel() end
commands.customize = function(arg) ns.ShowEditor(arg) end
commands.deck = function(arg) ns.ShowGuide(arg) end

-- CVar names are case-insensitive, but overrides are keyed by our spelling
local function CanonicalCVar(name)
	if not name then return nil end
	for cvar in pairs(ns.CVarMeta) do
		if cvar:lower() == name:lower() then return cvar end
	end
end

commands.set = function(arg)
	local key, name, value = (arg or ""):match("^(%S+)%s+(%S+)%s+(%S+)$")
	local cvar = CanonicalCVar(name)
	if not key or not ns.GetPreset(key) or not cvar then
		ns.Print("Usage: /deckforever set <preset> <cvar> <value>, e.g. set battery maxFPS 45")
		return
	end
	local good, why = ns.SetOverride(key, cvar, value)
	if good then
		ns.Print("%s: %s = %s. Apply the preset to use it.", ns.GetPreset(key).label, cvar, value)
	else
		ns.Print("Not set: %s %s.", cvar, why)
	end
end

commands.reset = function(arg)
	local key, name = (arg or ""):match("^(%S+)%s*(%S*)$")
	if not key or not ns.GetPreset(key) then
		ns.Print("Usage: /deckforever reset <preset> [cvar]")
		return
	end
	if name ~= "" then
		local cvar = CanonicalCVar(name)
		if not cvar then
			ns.Print("Unknown setting %q.", name)
			return
		end
		ns.SetOverride(key, cvar, nil)
		ns.Print("%s: %s back to the preset value.", ns.GetPreset(key).label, cvar)
	else
		ns.ResetOverrides(key)
		ns.Print("%s: all settings back to the preset values.", ns.GetPreset(key).label)
	end
end
commands.menu = function() ns.ToggleMenu() end

commands.uiscale = function(arg)
	if arg == "off" or arg == "default" then
		ns.SetUIScale(nil)
		return
	end
	local v = tonumber(arg)
	if not v or v < 0.5 or v > 1.0 then
		ns.Print("Usage: /deckforever uiscale <0.5-1.0>|default   (about 0.75 suits the Deck's screen)")
		return
	end
	ns.SetUIScale(v)
end

commands.minimap = function(arg)
	if arg ~= "on" and arg ~= "off" then
		ns.Print("Usage: /deckforever minimap on|off")
		return
	end
	ns.SetMinimapShown(arg == "on")
end

commands.preview = function(arg)
	local rows = ns.PreviewPreset(arg)
	if not rows then
		ns.Print("Unknown preset %q.", tostring(arg))
		return
	end
	for _, r in ipairs(rows) do
		if r.status == "change" then
			ns.Print("  %s: %s -> %s", r.name, tostring(r.current), r.target)
		elseif r.status == "unknown" then
			ns.Print("  |cffaaaaaa%s: not in this client, skipped|r", r.name)
		end
	end
	ns.Print("%s: %d would change.", ns.GetPreset(arg).label, ns.PresetDrift(arg))
end

commands.fps = function()
	local cap = C_CVar.GetCVar("useMaxFPS") == "1" and C_CVar.GetCVar("maxFPS") or "none"
	ns.Print("%.1f fps, cap %s", GetFramerate(), cap)
end

commands.status = function()
	local db = ns.DB
	local active = db.activePreset and ns.GetPreset(db.activePreset).label or "none"
	if db.activePreset then
		local drift = ns.PresetDrift(db.activePreset)
		if drift > 0 then active = ("%s (%d changed since)"):format(active, drift) end
	end
	ns.Print("Active preset: %s", active)
	if db.snapshot then
		ns.Print("Snapshot: %s, build %s", date("%Y-%m-%d %H:%M", db.snapshot.taken), tostring(db.snapshot.build))
	else
		ns.Print("Snapshot: none")
	end
	local o = db.options
	ns.Print("Raid twins %s, reminder %s (%d min, %d%% sag)",
		OnOff(o.syncRaid), OnOff(o.reminder), o.reminderMinutes, o.reminderSagPct)
end

commands.raid = function(arg)
	if arg ~= "on" and arg ~= "off" then
		ns.Print("Usage: /deckforever raid on|off")
		return
	end
	ns.DB.options.syncRaid = arg == "on"
	ns.Print("Raid twins %s. Takes effect on the next apply.", arg)
end

commands.reminder = function(arg)
	local o = ns.DB.options
	local minutes = tonumber(arg)
	if arg == "on" or minutes then
		o.reminder = true
		if minutes then o.reminderMinutes = math.max(10, math.floor(minutes)) end
		ns.StartReminder()
		ns.Print("Reminder on: after %d minutes, if fps drops %d%% below the start of the session.",
			o.reminderMinutes, o.reminderSagPct)
	elseif arg == "off" then
		o.reminder = false
		ns.StopReminder()
		ns.Print("Reminder off.")
	else
		ns.Print("Usage: /deckforever reminder on|off|<minutes>")
	end
end

commands.help = function()
	for _, line in ipairs(HELP) do ns.Print(line) end
end

function ns.HandleSlash(msg)
	local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
	if cmd == "" then
		ns.TogglePanel()
		return
	end
	local fn = commands[cmd]
	if fn then
		fn(arg ~= "" and arg or nil)
	else
		ns.Print("Unknown command %q.", cmd)
		commands.help()
	end
end

SLASH_DECKFOREVER1 = "/deckforever"
SlashCmdList.DECKFOREVER = ns.HandleSlash
