-- Customize tab: preset selector, a rail of setting groups, and < value > stepper rows for the
-- selected group. Changes are overrides on top of the built-in preset (ns.SetOverride).
local _, ns = ...

local W = ns.Widgets
local Window = ns.Window

local RAIL_W, ROW_W = 160, 520
local ROW_H, NOTE_H = 34, 12
local LIST_TOP = -70

local function Key() return Window.SelectedKey() end

local function LevelIndex(levels, value)
	if value == nil then return nil end
	for i, l in ipairs(levels) do
		if ns.ValuesEqual(l.value, value) then return i end
	end
	-- a hand-set value that is not one of the levels: place it between its neighbours
	local n = tonumber(value)
	if not n then return nil end
	for i, l in ipairs(levels) do
		if n < l.value then return i - 0.5 end
	end
	return #levels + 0.5
end

local function Step(setting, dir)
	local levels = setting.levels
	local idx = LevelIndex(levels, ns.EffectiveValue(Key(), setting.cvar)) or 1
	local target = dir > 0 and math.floor(idx + 1) or math.ceil(idx - 1)
	target = math.max(1, math.min(#levels, target))
	ns.SetOverride(Key(), setting.cvar, levels[target].value)
end

local function BuildRow(page, setting)
	local row = CreateFrame("Frame", nil, page)
	row:SetSize(ROW_W, ROW_H + (setting.note and NOTE_H or 0))
	row.setting = setting

	row.label = W.Text(row, "GameFontHighlight", setting.label)
	row.label:SetPoint("TOPLEFT", 8, -9)
	if setting.note then
		row.note = W.Text(row, "GameFontHighlightSmall", W.Color("muted", setting.note))
		row.note:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -2)
	end
	row.now = W.Text(row, "GameFontHighlightSmall")
	row.now:SetPoint("TOPLEFT", 176, -10)
	row.now:SetWidth(84)
	row.now:SetJustifyH("LEFT")

	row.prev = W.Button(row, "<", 40, 30, function() Step(setting, -1) end)
	row.prev:SetPoint("TOPLEFT", 262, -2)
	row.value = W.Text(row, "GameFontNormal")
	row.value:SetPoint("TOPLEFT", 304, -10)
	row.value:SetWidth(104)
	row.next = W.Button(row, ">", 40, 30, function() Step(setting, 1) end)
	row.next:SetPoint("TOPLEFT", 410, -2)
	row.reset = W.Button(row, "Reset", 60, 28, function() ns.SetOverride(Key(), setting.cvar, nil) end)
	row.reset:SetPoint("TOPLEFT", 456, -3)

	function row.Refresh()
		local key = Key()
		local value = ns.EffectiveValue(key, setting.cvar)
		local overridden = ns.GetOverrides(key)[setting.cvar] ~= nil
		local text = ns.LevelText(setting.cvar, value)
		row.value:SetText(overridden and W.Color("custom", text) or text)
		row.now:SetText(W.Color("muted", "now " .. ns.LevelText(setting.cvar, C_CVar.GetCVar(setting.cvar))))
		local idx = LevelIndex(setting.levels, value) or 1
		row.prev:SetEnabled(idx > 1)
		row.next:SetEnabled(idx < #setting.levels)
		row.reset:SetShown(overridden)
	end
	return row
end

ns.Window.RegisterTab("customize", "Customize", function(page)
	page.group = 1

	page.presets = W.Segmented(page, W.PresetItems(), 100, 36, Window.SetSelectedKey)
	for i, b in ipairs(page.presets) do b:SetPoint("TOPLEFT", 8 + (i - 1) * 104, -6) end
	page.presetButtons = page.presets.buttons

	page.apply = W.Button(page, "Apply", 150, 36, function() ns.ApplyPreset(Key()) end)
	page.apply:SetPoint("TOPRIGHT", -8, -6)

	-- two clicks to reset: no modal popups (they fight the gamepad cursor)
	page.resetAll = W.Button(page, "Reset all", 110, 36)
	page.resetAll:SetPoint("RIGHT", page.apply, "LEFT", -8, 0)
	local armed = false
	local function Disarm()
		armed = false
		page.resetAll:SetText("Reset all")
	end
	page.resetAll:SetScript("OnClick", function()
		if armed then
			Disarm()
			ns.ResetOverrides(Key())
		else
			armed = true
			page.resetAll:SetText("Click again")
			C_Timer.After(3, function() if armed then Disarm() end end)
		end
	end)

	page.summary = W.Text(page, "GameFontHighlight")
	page.summary:SetPoint("TOPLEFT", 10, -50)

	-- group rail
	page.groupButtons = {}
	for i, group in ipairs(ns.SETTING_GROUPS) do
		local b = W.Button(page, group.label, RAIL_W, 40, function()
			page.group = i
			page.Refresh()
		end)
		b:SetPoint("TOPLEFT", 8, LIST_TOP - (i - 1) * 46)
		page.groupButtons[i] = b
	end
	page.legend = W.Text(page, "GameFontHighlightSmall",
		W.Color("custom", "Gold") .. " = changed.\nRaid and battleground\nsettings follow these.")
	page.legend:SetPoint("TOPLEFT", 12, LIST_TOP - #ns.SETTING_GROUPS * 46 - 6)
	page.legend:SetJustifyH("LEFT")
	page.status = W.Text(page, "GameFontHighlightSmall")
	page.status:SetPoint("BOTTOMLEFT", 10, 6)

	-- rows, laid out per group in the same area
	page.rows, page.groupRows = {}, {}
	for gi, group in ipairs(ns.SETTING_GROUPS) do
		local y = LIST_TOP
		page.groupRows[gi] = {}
		for _, setting in ipairs(group.settings) do
			local row = BuildRow(page, setting)
			row:SetPoint("TOPLEFT", RAIL_W + 16, y)
			y = y - ROW_H - (setting.note and NOTE_H or 0)
			page.rows[#page.rows + 1] = row
			table.insert(page.groupRows[gi], row)
		end
	end

	function page.Refresh()
		local key = Key()
		local preset = ns.Presets[key]
		page.presets.Select(key)
		for k, b in pairs(page.presetButtons) do
			b:SetText(ns.Presets[k].label .. (ns.HasOverrides(k) and " *" or ""))
		end
		for i, b in ipairs(page.groupButtons) do
			if i == page.group then b:LockHighlight() else b:UnlockHighlight() end
		end
		local n = 0
		for _ in pairs(ns.GetOverrides(key)) do n = n + 1 end
		page.summary:SetText(("%s: %s.  %s"):format(preset.label, preset.desc,
			n > 0 and W.Color("custom", n .. " customized") or W.Color("muted", "Built-in values.")))
		for gi, rows in ipairs(page.groupRows) do
			for _, row in ipairs(rows) do
				row:SetShown(gi == page.group)
				row.Refresh()
			end
		end
		page.apply:SetText("Apply " .. preset.label)
		page.resetAll:SetEnabled(n > 0)
		local status = ""
		if ns.DB.activePreset == key and ns.PresetDrift(key) > 0 then
			status = W.Color("pending", preset.label .. " is active: press Apply to use these values.")
		end
		page.status:SetText(status)
	end
end)
