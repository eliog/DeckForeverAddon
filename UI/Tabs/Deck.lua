-- Steam Deck tab: the Quick Access Menu settings to pair with the selected preset, and the ones
-- that are the same for every preset. An addon cannot change these; the player sets them once.
local _, ns = ...

local W = ns.Widgets
local Window = ns.Window

local COL_W, ROW_H = 330, 42

local function MakeRows(page, count, x, y)
	local rows = {}
	for i = 1, count do
		local row = CreateFrame("Frame", nil, page)
		row:SetSize(COL_W, ROW_H)
		row:SetPoint("TOPLEFT", x, y - (i - 1) * ROW_H)
		row.setting = W.Text(row, "GameFontHighlight")
		row.setting:SetPoint("TOPLEFT", 4, -2)
		row.value = W.Text(row, "GameFontNormal")
		row.value:SetPoint("TOPRIGHT", -8, -2)
		row.why = W.Text(row, "GameFontHighlightSmall")
		row.why:SetPoint("TOPLEFT", 4, -18)
		row.why:SetWidth(COL_W - 12)
		row.why:SetJustifyH("LEFT")
		rows[i] = row
	end
	return rows
end

local function Fill(rows, data)
	for i, row in ipairs(rows) do
		local d = data[i]
		row:SetShown(d ~= nil)
		if d then
			row.setting:SetText(d.setting)
			row.value:SetText(W.Color("custom", d.value))
			row.why:SetText(W.Color("muted", d.why))
		end
	end
end

ns.Window.RegisterTab("deck", "Steam Deck", function(page)
	page.presets = W.Segmented(page, W.PresetItems(), 130, 36, Window.SetSelectedKey)
	for i, b in ipairs(page.presets) do b:SetPoint("TOPLEFT", 8 + (i - 1) * 136, -6) end
	page.presetButtons = page.presets.buttons

	page.where = W.Text(page, "GameFontHighlight", ns.DECK_GUIDE.where)
	page.where:SetPoint("TOPLEFT", 10, -52)

	local top = -80
	page.presetHeader = W.Text(page, "GameFontNormalLarge")
	page.presetHeader:SetPoint("TOPLEFT", 10, top)
	local maxRows = 0
	for _, rows in pairs(ns.DECK_GUIDE.presets) do maxRows = math.max(maxRows, #rows) end
	page.presetRows = MakeRows(page, maxRows, 8, top - 26)

	page.note = W.Text(page, "GameFontHighlightSmall", W.Color("muted",
		"Keep the Deck's Framerate Limit equal to the\npreset's Max FPS: the lower one wins, and a\nmismatch makes frame pacing uneven."))
	page.note:SetPoint("TOPLEFT", 12, top - 26 - maxRows * ROW_H - 12)
	page.note:SetJustifyH("LEFT")

	page.commonHeader = W.Text(page, "GameFontNormalLarge", "Every preset")
	page.commonHeader:SetPoint("TOPLEFT", COL_W + 24, top)
	page.commonRows = MakeRows(page, #ns.DECK_GUIDE.common, COL_W + 22, top - 26)
	Fill(page.commonRows, ns.DECK_GUIDE.common)

	function page.Refresh()
		local key = Window.SelectedKey()
		page.presets.Select(key)
		for k, b in pairs(page.presetButtons) do
			b:SetText(ns.Presets[k].label .. (ns.DB.activePreset == k and " (active)" or ""))
		end
		page.presetHeader:SetText(ns.Presets[key].label)
		Fill(page.presetRows, ns.DECK_GUIDE.presets[key])
	end
end)
