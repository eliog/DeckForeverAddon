-- Steam Deck tab: a picture of the Deck's Quick Access Menu > Performance page, set the way the
-- selected preset wants it, so the player can copy it row by row with the real menu open next to
-- it. Rows that change between presets are marked; the reasons are listed on the right.
-- An addon cannot change these settings.
local _, ns = ...

local W = ns.Widgets
local Window = ns.Window
local unpack = unpack or table.unpack

-- SteamOS colours
local BG = { 0.11, 0.13, 0.17 }
local HEAD = { 0.15, 0.17, 0.22 }
local LINE = { 0.22, 0.25, 0.30 }
local BLUE = { 0.10, 0.62, 1.00 }
local OFF = { 0.33, 0.36, 0.41 }
local KNOB = { 0.92, 0.93, 0.94 }
local BUTTON = { 0.30, 0.33, 0.39 }

local PANEL_W, ROW_H, SECTION_H, HEAD_H = 380, 27, 20, 26
local CTRL_W = 130

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

-- slider: a track filled blue up to the knob
local function Slider(row)
	local c = CreateFrame("Frame", nil, row)
	c:SetSize(CTRL_W, 4)
	c:SetPoint("RIGHT", -12, 0)
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

local function MakeRow(panel)
	local row = CreateFrame("Frame", nil, panel)
	row:SetSize(PANEL_W, ROW_H)
	row.mark = Rect(row, BLUE)
	row.mark:SetPoint("TOPLEFT", 0, -3)
	row.mark:SetPoint("BOTTOMLEFT", 0, 3)
	row.mark:SetWidth(3)
	row.line = Rect(row, LINE)
	row.line:SetPoint("BOTTOMLEFT", 10, 0)
	row.line:SetPoint("BOTTOMRIGHT", -10, 0)
	row.line:SetHeight(1)
	row.button = Rect(row, BUTTON, "BORDER")
	row.button:SetPoint("TOPLEFT", 10, -3)
	row.button:SetPoint("BOTTOMRIGHT", -10, 4)
	row.setting = W.Text(row, "GameFontHighlight")
	row.value = W.Text(row, "GameFontHighlightSmall")
	row.toggle = Toggle(row)
	row.slider = Slider(row)
	return row
end

local function FillRow(row, def, r)
	local kind = def.kind
	row:SetHeight(kind == "section" and SECTION_H or ROW_H)
	row.mark:SetShown(r.varies)
	row.line:SetShown(kind ~= "section" and kind ~= "button")
	row.button:SetShown(kind == "button")
	row.toggle:SetShown(kind == "toggle")
	row.slider:SetShown(kind == "slider" or kind == "choice")
	row.setting:ClearAllPoints()
	row.value:ClearAllPoints()
	row.value:SetText("")
	if kind == "section" then
		row.setting:SetFontObject("GameFontNormalSmall")
		row.setting:SetPoint("BOTTOMLEFT", 12, 3)
		row.setting:SetText(def.label)
		return
	end
	row.setting:SetFontObject("GameFontHighlight")
	if kind == "button" then
		row.setting:SetPoint("CENTER", 0, 0)
		row.setting:SetText(def.label)
		return
	end
	row.setting:SetPoint("LEFT", def.sub and 26 or 12, 0)
	row.setting:SetText(def.label)
	if kind == "toggle" then
		row.toggle.Set(r.value)
	elseif kind == "slider" then
		row.slider.Set((r.value - def.min) / (def.max - def.min))
	elseif kind == "choice" then
		local index = 1
		for i, c in ipairs(def.choices) do if c == r.value then index = i end end
		row.slider.Set((index - 1) / (#def.choices - 1))
	end
	if kind ~= "toggle" then
		row.value:SetPoint("RIGHT", row.slider, "LEFT", -8, 0)
		row.value:SetText(r.varies and W.Color("custom", r.text) or r.text)
	end
end

ns.Window.RegisterTab("deck", "Steam Deck", function(page)
	-- the Quick Access panel, on the left
	local panel = CreateFrame("Frame", nil, page)
	panel:SetPoint("TOPLEFT", 6, -4)
	panel:SetWidth(PANEL_W)
	panel.bg = Rect(panel, BG, "BACKGROUND")
	panel.bg:SetAllPoints()
	panel.head = Rect(panel, HEAD, "BORDER")
	panel.head:SetPoint("TOPLEFT")
	panel.head:SetPoint("TOPRIGHT")
	panel.head:SetHeight(HEAD_H)
	panel.title = W.Text(panel, "GameFontNormalLarge", "Performance")
	panel.title:SetPoint("TOPLEFT", 12, -5)
	page.panel = panel

	page.rows = {}
	for i in ipairs(ns.DECK_GUIDE.rows) do page.rows[i] = MakeRow(panel) end

	-- right: pick a preset, then why the marked rows are set that way
	local x = PANEL_W + 18
	page.presets = W.Segmented(page, W.PresetItems(), 150, 30, Window.SetSelectedKey)
	for i, b in ipairs(page.presets) do b:SetPoint("TOPLEFT", x, -4 - (i - 1) * 34) end
	page.presetButtons = page.presets.buttons

	local top = -4 - #page.presets * 34 - 6
	page.presetHeader = W.Text(page, "GameFontNormalLarge")
	page.presetHeader:SetPoint("TOPLEFT", x + 2, top)
	page.where = W.Text(page, "GameFontHighlightSmall", ns.DECK_GUIDE.where)
	page.where:SetPoint("TOPLEFT", x + 2, top - 22)
	page.where:SetWidth(230)
	page.where:SetJustifyH("LEFT")
	page.why = W.Text(page, "GameFontHighlightSmall")
	page.why:SetPoint("TOPLEFT", x + 2, top - 52)
	page.why:SetWidth(230)
	page.why:SetJustifyH("LEFT")

	function page.Refresh()
		local key = Window.SelectedKey()
		page.presets.Select(key)
		for k, b in pairs(page.presetButtons) do
			b:SetText(ns.Presets[k].label .. (ns.DB.activePreset == k and " *" or ""))
		end
		page.presetHeader:SetText(ns.Presets[key].label)

		local y, lines = -HEAD_H, {}
		for i, def in ipairs(ns.DECK_GUIDE.rows) do
			local row = page.rows[i]
			local r = (def.kind == "section" or def.kind == "button") and { varies = false } or ns.DeckRow(def, key)
			row:SetShown(r ~= nil)
			if r then
				FillRow(row, def, r)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", 0, y)
				y = y - (def.kind == "section" and SECTION_H or ROW_H)
				if r.varies then
					lines[#lines + 1] = ("%s  %s\n%s"):format(def.label, W.Color("custom", r.text), W.Color("muted", r.why))
				end
			end
		end
		panel:SetHeight(-y + 4)
		page.why:SetText(table.concat(lines, "\n\n")
			.. "\n\n" .. W.Color("muted", "Blue-marked rows change between presets; the rest are the same for all."))
	end
end)
