-- Guide: Steam Deck Quick Access Menu settings that go with each preset (pure data).
-- An addon cannot change these; the user sets them once in a per-game profile.
-- Names follow SteamOS's Quick Access Menu > Performance tab.
local _, ns = ...

ns.DECK_GUIDE = {
	where = "Press the ... button, open Performance (battery icon).",

	-- The Quick Access Menu > Performance rows, top to bottom. kind: toggle | slider | choice.
	-- value is the same for every preset unless presets[key] gives one; text overrides the shown value.
	rows = {
		{ id = "overlay", label = "Performance Overlay Level", kind = "slider", min = 0, max = 4, value = 0,
			text = "Off", why = "Level 2 shows fps and battery watts, if you are curious" },
		{ id = "profile", label = "Use per-game profile", kind = "toggle", value = true,
			why = "These settings then apply to WoW only" },
		{ id = "refresh", label = "Refresh Rate", kind = "slider", min = 45, max = 90, unit = " Hz",
			presets = {
				battery = { value = 90, why = "30 fps shown three times (LCD Deck: 60 Hz)" },
				balanced = { value = 90, why = "45 fps shown twice (LCD Deck: 40 Hz, and Max FPS 40 in Customize)" },
				performance = { value = 60, why = "Matches the 60 fps cap" },
				quality = { value = 90, why = "30 fps shown three times (LCD Deck: 60 Hz)" },
			} },
		{ id = "limit", label = "Framerate Limit", kind = "slider", min = 0, max = 90, unit = " FPS",
			presets = {
				battery = { value = 30, why = "Same as the preset's cap. Off works too: the game caps itself" },
				balanced = { value = 45, why = "Same as the preset's cap. Off works too" },
				performance = { value = 60, why = "Same as the preset's cap. Off works too" },
				quality = { value = 30, why = "Same as the preset's cap. Off works too" },
			} },
		{ id = "advanced", label = "Show advanced view", kind = "toggle", value = true,
			why = "Shows the settings below" },
		{ id = "tearing", label = "Allow Tearing", kind = "toggle", value = false, why = "The game uses VSync" },
		{ id = "hrs", label = "Half Rate Shading", kind = "toggle", value = false, why = "Blurs the picture for little gain" },
		{ id = "tdp", label = "TDP Limit", kind = "toggle",
			presets = {
				battery = { value = true, why = "Limits the chip's power: the battery saver" },
				balanced = { value = true, why = "Limits the chip's power: the battery saver" },
				performance = { value = false, why = "Full power (15 W)" },
				quality = { value = false, why = "Full power; best plugged in" },
			} },
		{ id = "watts", label = "Watts", kind = "slider", min = 3, max = 15, unit = " W", sub = true,
			presets = {
				battery = { value = 10, text = "8-10 W", why = "At 30 fps 8 W saves a little more; same picture" },
				balanced = { value = 10, why = "Measured about 3.7 h questing" },
			} },
		{ id = "gpu", label = "Manual GPU Clock Control", kind = "toggle", value = false,
			why = "Let the Deck balance CPU and GPU" },
		{ id = "filter", label = "Scaling Filter", kind = "choice", value = "Linear",
			choices = { "Linear", "Pixel", "FSR", "NIS" },
			why = "FSR/NIS here blur the interface; the presets use the game's own upscaler" },
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
		elseif row.kind == "slider" then text = (row.id == "limit" and value == 0) and "Off" or (value .. (row.unit or ""))
		else text = tostring(value) end
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
