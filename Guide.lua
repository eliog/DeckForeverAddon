-- Guide: Steam Deck Quick Access Menu settings that go with each preset (pure data).
-- An addon cannot change these; the user sets them once in a per-game profile.
-- Names follow SteamOS's Quick Access Menu > Performance tab.
local _, ns = ...

ns.DECK_GUIDE = {
	-- The Quick Access Menu > Performance rows, top to bottom, as SteamOS shows them with the
	-- advanced view open. kind: toggle | slider | choice | button | section. value is the same for
	-- every preset unless presets[key] gives one; text overrides the shown value.
	rows = {
		{ id = "overlay", label = "Performance Overlay Level", kind = "choice", value = "Off",
			choices = { "Off", "1", "2", "3", "4" }, why = "Level 2 shows fps and battery watts, if you are curious" },
		{ id = "advanced", label = "Basic View", kind = "button",
			why = "Tap Advanced View until the button reads Basic View: the settings below appear" },
		{ id = "section", label = "PERFORMANCE SETTINGS", kind = "section" },
		{ id = "profile", label = "Use per-game profile", kind = "toggle", value = true,
			why = "These settings then apply to WoW only" },
		{ id = "limit", label = "Frame Limit", kind = "slider", min = 10, max = 90,
			presets = {
				battery = { value = 30, text = "30 FPS (90 Hz)", why = "Same as the preset's cap; 30 fps shown three times on the OLED (LCD: 30 FPS at 60 Hz)" },
				balanced = { value = 45, text = "45 FPS (90 Hz)", why = "Same as the preset's cap; 45 fps shown twice (LCD: 40 FPS, and Max FPS 40 in Customize)" },
				performance = { value = 60, text = "60 FPS (60 Hz)", why = "Same as the preset's cap" },
				quality = { value = 30, text = "30 FPS (90 Hz)", why = "Same as the preset's cap; 30 fps shown three times" },
			} },
		{ id = "nolimit", label = "Disable Frame Limit", kind = "toggle", value = false,
			why = "On works too: the preset caps the game itself" },
		{ id = "tearing", label = "Allow Tearing", kind = "toggle", value = false, why = "The game uses VSync" },
		{ id = "hrs", label = "Half Rate Shading", kind = "toggle", value = false, why = "Blurs the picture for little gain" },
		{ id = "tdp", label = "TDP Limit", kind = "toggle",
			presets = {
				battery = { value = true, why = "Limits the chip's power: the battery saver" },
				balanced = { value = true, why = "Limits the chip's power: the battery saver" },
				performance = { value = false, why = "Full power (15 W)" },
				quality = { value = false, why = "Full power; best plugged in" },
			} },
		{ id = "watts", label = "Watts", kind = "slider", min = 3, max = 15, sub = true,
			presets = {
				battery = { value = 10, text = "8-10 Watts", why = "At 30 fps 8 W saves a little more; same picture" },
				balanced = { value = 10, text = "10 Watts", why = "Measured about 3.7 h questing" },
			} },
		{ id = "gpu", label = "Manual GPU Clock", kind = "toggle", value = false,
			why = "Let the Deck balance CPU and GPU" },
		{ id = "mode", label = "Scaling Mode", kind = "choice", value = "Auto",
			choices = { "Auto", "Integer", "Fit", "Stretch", "Fill" }, why = "The game already runs at the screen's size" },
		{ id = "filter", label = "Scaling Filter", kind = "choice", value = "Linear",
			choices = { "Linear", "Pixel", "Sharp" },
			why = "Sharp/FSR here also sharpens the interface; the presets use the game's own upscaler" },
		{ id = "steamoverlay", label = "Show Perf Overlay in Steam", kind = "toggle", value = false,
			why = "Only affects Steam's own screens" },
	},
}

-- One row for a preset: value, shown text, why, and whether it differs between presets.
-- Returns nil when the row does not apply (e.g. Watts with the TDP limit off).
function ns.DeckRow(row, key)
	local p = row.presets and row.presets[key]
	if row.presets and not p then return nil end
	local value = p and p.value
	if value == nil then value = row.value end
	local text = (p and p.text) or (not p and row.text)
	if not text then
		if row.kind == "toggle" then text = value and "On" or "Off"
		elseif row.kind == "slider" then text = value .. (row.unit or "")
		else text = value and tostring(value) or "" end
	end
	return { value = value, text = text, why = (p and p.why) or row.why, varies = row.presets ~= nil }
end

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

-- One line for chat after applying a preset: the rows that change between presets.
function ns.DeckSummary(key)
	if not ns.GetPreset(key) then return nil end
	local parts = {}
	for _, row in ipairs(ns.DECK_GUIDE.rows) do
		local r = row.presets and ns.DeckRow(row, key)
		if r then
			local label = row.id == "watts" and "TDP" or row.label
			if row.id ~= "tdp" or not r.value then parts[#parts + 1] = label .. " " .. (row.id == "tdp" and "Off" or r.text) end
		end
	end
	return table.concat(parts, ", ")
end
