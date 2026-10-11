-- Options tab: the addon's own settings and the game's UI scale.
local _, ns = ...

local W = ns.Widgets

local SCALES = { 1.0, 1.15, 1.3, 1.45 }

local function StepIndex(list, value)
	for i, v in ipairs(list) do
		if math.abs(v - value) < 1e-3 then return i end
	end
	return 2
end

ns.Window.RegisterTab("options", "Options", function(page)
	local o = ns.DB.options

	page.header = W.Text(page, "GameFontNormalLarge", "Options")
	page.header:SetPoint("TOPLEFT", 12, -10)

	page.raid = W.Toggle(page, "Raid & battleground settings", 320,
		function() return o.syncRaid end, function(v) o.syncRaid = v end)
	page.raid:SetPoint("TOPLEFT", 10, -36)
	page.raidHelp = W.Text(page, "GameFontHighlightSmall", W.Color("muted",
		"Presets also set the game's separate raid and battleground values, a notch lower."))
	page.raidHelp:SetPoint("TOPLEFT", 14, -76)
	page.raidHelp:SetWidth(320)
	page.raidHelp:SetJustifyH("LEFT")

	page.reminder = W.Toggle(page, "Relog reminder when fps sags", 320,
		function() return o.reminder end, function(v)
			o.reminder = v
			if v then ns.StartReminder() else ns.StopReminder() end
		end)
	page.reminder:SetPoint("TOPLEFT", 10, -110)
	page.minutes = W.Stepper(page, 320,
		function() return ("Remind after %d min"):format(o.reminderMinutes) end,
		function(dir) o.reminderMinutes = math.max(30, math.min(240, o.reminderMinutes + dir * 15)) end)
	page.minutes:SetPoint("TOPLEFT", 10, -150)

	page.minimap = W.Toggle(page, "Minimap button", 320,
		function() return not o.minimap.hide end, function(v) ns.SetMinimapShown(v) end)
	page.minimap:SetPoint("TOPLEFT", 10, -200)

	-- right column: sizes
	page.sizeHeader = W.Text(page, "GameFontNormalLarge", "Size")
	page.sizeHeader:SetPoint("TOPLEFT", 352, -10)

	page.scale = W.Stepper(page, 320,
		function() return ("This window %d%%"):format(math.floor(o.window.scale * 100 + 0.5)) end,
		function(dir)
			local i = StepIndex(SCALES, o.window.scale) + dir
			o.window.scale = SCALES[math.max(1, math.min(#SCALES, i))]
			ns.Window.ApplyScale()
		end)
	page.scale:SetPoint("TOPLEFT", 350, -36)

	-- the game's UI scale: its own setting is locked in Forever, so DeckForever scales the interface
	local US = ns.UI_SCALE_STEPS
	page.uiScale = W.Stepper(page, 320,
		function()
			local s = o.uiScale
			return s and ("Game interface %d%%"):format(math.floor(s * 100 + 0.5)) or "Game interface: default"
		end,
		function(dir)
			local i = o.uiScale and StepIndex(US, o.uiScale) or #US + 1 -- default sits past 100%
			i = i + dir
			if i > #US then ns.SetUIScale(nil) else ns.SetUIScale(US[math.max(1, i)]) end
		end)
	page.uiScale:SetPoint("TOPLEFT", 350, -80)
	page.uiScaleHelp = W.Text(page, "GameFontHighlightSmall", W.Color("muted",
		"About 75% suits the Deck's 7-inch screen. The game's own\nUI Scale option is locked; this scales the interface instead."))
	page.uiScaleHelp:SetPoint("TOPLEFT", 354, -120)
	page.uiScaleHelp:SetJustifyH("LEFT")

	function page.Refresh()
		page.raid.Refresh()
		page.reminder.Refresh()
		page.minutes.Refresh()
		page.minimap.Refresh()
		page.scale.Refresh()
		page.uiScale.Refresh()
	end
end)
