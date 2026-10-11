-- Steam Deck tab: a picture of the Deck's Quick Access Menu > Performance page, set the way the
-- selected preset wants it, so the player can copy it row by row. Rows that change between
-- presets are marked; the reasons are listed on the right. An addon cannot change these.
local _, ns = ...

local W = ns.Widgets
local unpack = unpack or table.unpack
local Window = ns.Window

-- SteamOS colours
local BG = { 0.09, 0.10, 0.12 }
local PANEL = { 0.14, 0.15, 0.18 }
local LINE = { 0.22, 0.24, 0.28 }
local BLUE = { 0.10, 0.62, 1.00 }
local OFF = { 0.33, 0.36, 0.41 }
local KNOB = { 0.86, 0.87, 0.88 }

local PANEL_W, ROW_H, TOP = 380, 28, -50
local CTRL_W = 120

local function Rect(parent, color, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
	return t
end

-- toggle: a pill with a knob, blue when on
local function Toggle(row)
	local c = CreateFrame("Frame", nil, row)
	c:SetSize(34, 16)
	c:SetPoint("RIGHT", -10, 0)
	c.track = Rect(c, OFF)
	c.track:SetAllPoints()
	c.knob = Rect(c, KNOB, "OVERLAY")
	c.knob:SetSize(12, 12)
	function c.Set(on)
		c.track:SetColorTexture(unpack(on and BLUE or OFF))
		c.knob:ClearAllPoints()
		c.knob:SetPoint(on and "RIGHT" or "LEFT", on and -2 or 2, 0)
	end
	return c
end

-- slider: a track filled blue up to the knob, the value to its left
local function Slider(row)
	local c = CreateFrame("Frame", nil, row)
	c:SetSize(CTRL_W, 4)
	c:SetPoint("RIGHT", -10, 0)
	c.track = Rect(c, OFF)
	c.track:SetAllPoints()
	c.fill = Rect(c, BLUE)
	c.fill:SetPoint("LEFT")
	c.fill:SetHeight(4)
	c.knob = Rect(c, KNOB, "OVERLAY")
	c.knob:SetSize(10, 14)
	function c.Set(frac)
		frac = math.max(0, math.min(1, frac))
		c.fill:SetWidth(math.max(1, CTRL_W * frac))
		c.knob:ClearAllPoints()
		c.knob:SetPoint("CENTER", c, "LEFT", CTRL_W * frac, 0)
	end
	return c
end

local function MakeRow(panel, i)
	local row = CreateFrame("Frame", nil, panel)
	row:SetSize(PANEL_W - 8, ROW_H)
	row:SetPoint("TOPLEFT", 4, -26 - (i - 1) * ROW_H)
	row.mark = Rect(row, BLUE)
	row.mark:SetPoint("TOPLEFT", 0, -3)
	row.mark:SetPoint("BOTTOMLEFT", 0, 3)
	row.mark:SetWidth(3)
	row.line = Rect(row, LINE)
	row.line:SetPoint("BOTTOMLEFT", 8, 0)
	row.line:SetPoint("BOTTOMRIGHT", -8, 0)
	row.line:SetHeight(1)
	row.setting = W.Text(row, "GameFontHighlight")
	row.setting:SetPoint("LEFT", 12, 0)
	row.value = W.Text(row, "GameFontHighlightSmall")
	row.toggle = Toggle(row)
	row.slider = Slider(row)
	return row
end

local function FillRow(row, def, r)
	row.setting:SetText(def.sub and ("    " .. def.label) or def.label)
	row.mark:SetShown(r.varies)
	row.toggle:SetShown(def.kind == "toggle")
	row.slider:SetShown(def.kind == "slider")
	row.value:ClearAllPoints()
	if def.kind == "toggle" then
		row.toggle.Set(r.value)
		row.value:SetText("")
	elseif def.kind == "slider" then
		row.slider.Set((r.value - def.min) / (def.max - def.min))
		row.value:SetPoint("RIGHT", row.slider, "LEFT", -8, 0)
		row.value:SetText(r.varies and W.Color("custom", r.text) or r.text)
	else
		row.value:SetPoint("RIGHT", -10, 0)
		row.value:SetText(r.text)
	end
end

ns.Window.RegisterTab("deck", "Steam Deck", function(page)
	page.presets = W.Segmented(page, W.PresetItems(), 130, 36, Window.SetSelectedKey)
	for i, b in ipairs(page.presets) do b:SetPoint("TOPLEFT", 8 + (i - 1) * 136, -6) end
	page.presetButtons = page.presets.buttons

	-- the Quick Access panel
	local panel = CreateFrame("Frame", nil, page)
	panel:SetPoint("TOPLEFT", 8, TOP)
	panel:SetSize(PANEL_W, 26 + #ns.DECK_GUIDE.rows * ROW_H + 6)
	panel.bg = Rect(panel, BG, "BACKGROUND")
	panel.bg:SetAllPoints()
	panel.head = Rect(panel, PANEL, "BORDER")
	panel.head:SetPoint("TOPLEFT")
	panel.head:SetPoint("TOPRIGHT")
	panel.head:SetHeight(24)
	panel.title = W.Text(panel, "GameFontNormal", "PERFORMANCE")
	panel.title:SetPoint("TOPLEFT", 12, -6)
	page.panel = panel

	page.rows = {}
	for i in ipairs(ns.DECK_GUIDE.rows) do page.rows[i] = MakeRow(panel, i) end

	-- right side: what to do, and why the marked rows are set that way
	local x = PANEL_W + 22
	page.presetHeader = W.Text(page, "GameFontNormalLarge")
	page.presetHeader:SetPoint("TOPLEFT", x, TOP)
	page.where = W.Text(page, "GameFontHighlightSmall", ns.DECK_GUIDE.where)
	page.where:SetPoint("TOPLEFT", x, TOP - 24)
	page.where:SetWidth(280)
	page.where:SetJustifyH("LEFT")
	page.why = W.Text(page, "GameFontHighlightSmall")
	page.why:SetPoint("TOPLEFT", x, TOP - 58)
	page.why:SetWidth(280)
	page.why:SetJustifyH("LEFT")
	page.legend = W.Text(page, "GameFontHighlightSmall", W.Color("muted",
		"Blue-marked rows change between presets.\nThe rest stay the same for all of them."))
	page.legend:SetPoint("BOTTOMLEFT", x, 10)
	page.legend:SetJustifyH("LEFT")

	function page.Refresh()
		local key = Window.SelectedKey()
		page.presets.Select(key)
		for k, b in pairs(page.presetButtons) do
			b:SetText(ns.Presets[k].label .. (ns.DB.activePreset == k and " (active)" or ""))
		end
		page.presetHeader:SetText(ns.Presets[key].label)

		local shown, lines = 0, {}
		for i, def in ipairs(ns.DECK_GUIDE.rows) do
			local row, r = page.rows[i], ns.DeckRow(def, key)
			row:SetShown(r ~= nil)
			if r then
				shown = shown + 1
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", 4, -26 - (shown - 1) * ROW_H)
				FillRow(row, def, r)
				if r.varies then
					lines[#lines + 1] = ("%s  %s\n%s"):format(def.label, W.Color("custom", r.text), W.Color("muted", r.why))
				end
			end
		end
		panel:SetHeight(26 + shown * ROW_H + 6)
		page.why:SetText(table.concat(lines, "\n\n"))
	end
end)
