-- Guide: Steam Deck Quick Access Menu settings that go with each preset (pure data).
-- An addon cannot change these; the user sets them once in a per-game profile.
-- Names follow SteamOS's Quick Access Menu > Performance tab.
local _, ns = ...

ns.DECK_GUIDE = {
	where = "Press the ... button, open Performance (battery icon), turn on Use per-game profile.",

	-- per preset: the settings that change between presets
	presets = {
		battery = {
			{ setting = "Refresh Rate", value = "90 Hz", why = "OLED: 30 fps shown three times. LCD: 60 Hz" },
			{ setting = "Framerate Limit", value = "Off or 30", why = "The preset caps the game itself; measured identical either way" },
			{ setting = "TDP Limit", value = "8-10 W", why = "At 30 fps the cap barely matters: ~12 W in cities either way" },
		},
		balanced = {
			{ setting = "Refresh Rate", value = "90 Hz", why = "OLED: 45 fps shown twice. LCD: 40 Hz and Max FPS 40 in Customize" },
			{ setting = "Framerate Limit", value = "Off or 45", why = "The preset caps the game itself" },
			{ setting = "TDP Limit", value = "10 W", why = "Measured ~13.7 W, ~3.7 h" },
		},
		performance = {
			{ setting = "Refresh Rate", value = "60 Hz", why = "Matches the 60 fps cap" },
			{ setting = "Framerate Limit", value = "Off or 60", why = "The preset caps the game itself" },
			{ setting = "TDP Limit", value = "Off", why = "Full 15 W: measured 17-19 W, ~2.6-3 h; cities reach ~40" },
		},
		quality = {
			{ setting = "Refresh Rate", value = "90 Hz", why = "30 fps shown three times (LCD: 60 Hz)" },
			{ setting = "Framerate Limit", value = "Off or 30", why = "The preset caps the game itself" },
			{ setting = "TDP Limit", value = "Off", why = "Full power; best plugged in" },
		},
	},

	-- the same for every preset
	common = {
		{ setting = "Use per-game profile", value = "On", why = "These settings then apply to WoW only" },
		{ setting = "Show Advanced View", value = "On", why = "Shows TDP Limit and GPU clock" },
		{ setting = "Allow Tearing", value = "Off", why = "The game uses VSync" },
		{ setting = "Half Rate Shading", value = "Off", why = "Blurs the picture for little gain" },
		{ setting = "Manual GPU Clock", value = "Off", why = "Let the Deck balance CPU and GPU" },
		{ setting = "Scaling Filter", value = "Linear", why = "FSR/NIS here blur the UI; use the game's Render Scale" },
		{ setting = "Performance Overlay", value = "Level 2 while testing", why = "Shows fps and battery watts" },
	},
}

-- Battery hours measured on a Steam Deck OLED (~50 Wh) with the built-in presets and the
-- settings above, questing and in a capital.
ns.DECK_HOURS = {
	battery = { questing = 4.5, city = 4.2 },
	balanced = { questing = 3.7, city = 3.2 },
	performance = { questing = 2.7, city = 2.3 },
	quality = { questing = 2.6, city = 2.3 },
}

-- "~3.9 h questing, ~3.2 h in cities", or nil when not measured
function ns.HoursText(key)
	local h = ns.DECK_HOURS[key]
	if not h then return nil end
	return ("~%.1f h questing, ~%.1f h in cities"):format(h.questing, h.city)
end

-- One line for chat after applying a preset, e.g. "60 Hz, Framerate Limit 60 FPS, TDP Off".
function ns.DeckSummary(key)
	local rows = ns.DECK_GUIDE.presets[key]
	if not rows then return nil end
	local parts = {}
	for _, r in ipairs(rows) do parts[#parts + 1] = r.setting .. " " .. r.value end
	return table.concat(parts, ", ")
end
