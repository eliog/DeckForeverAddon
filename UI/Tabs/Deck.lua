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

	-- right: which preset, then step by step what to do on the Deck
	local x, colW = PANEL_W + 18, 270
	page.preset = W.Text(page, "GameFontHighlight")
	page.preset:SetPoint("TOPLEFT", x, -6)
	page.title = W.Text(page, "GameFontNormalLarge", "Set up your Steam Deck")
	page.title:SetPoint("TOPLEFT", x, -26)
	page.intro = W.Text(page, "GameFontHighlightSmall", W.Color("muted",
		"The addon can't change these. Copy the picture on the left:"))
	page.intro:SetPoint("TOPLEFT", x, -48)
	page.intro:SetWidth(colW)
	page.intro:SetJustifyH("LEFT")

	-- a numbered step: blue badge, text, optional detail line
	local function Step(n, y)
		local f = CreateFrame("Frame", nil, page)
		f:SetSize(colW, 34)
		f:SetPoint("TOPLEFT", x, y)
		f.badge = Rect(f, BLUE)
		f.badge:SetSize(18, 18)
		f.badge:SetPoint("TOPLEFT", 0, 0)
		f.num = W.Text(f, "GameFontHighlight", tostring(n))
		f.num:SetPoint("CENTER", f.badge, "CENTER", 0, 0)
		f.text = W.Text(f, "GameFontHighlight")
		f.text:SetPoint("TOPLEFT", 26, -2)
		f.detail = W.Text(f, "GameFontHighlightSmall")
		f.detail:SetPoint("TOPLEFT", 26, -18)
		f.detail:SetWidth(colW - 26)
		f.detail:SetJustifyH("LEFT")
		return f
	end

	-- the Deck's "..." button: a dark pill with three dots
	local function DotsIcon(parent, anchor)
		local b = CreateFrame("Frame", nil, parent)
		b:SetSize(32, 16)
		b:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
		b.edge = Rect(b, KNOB, "BORDER")
		b.edge:SetAllPoints()
		b.bg = Rect(b, { 0.15, 0.16, 0.19 })
		b.bg:SetPoint("TOPLEFT", 1, -1)
		b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
		for i = -1, 1 do
			local d = Rect(b, KNOB, "OVERLAY")
			d:SetSize(4, 4)
			d:SetPoint("CENTER", i * 8, 0)
		end
		return b
	end

	page.steps = {}
	local s1 = Step(1, -74)
	s1.text:SetText("Press")
	s1.icon = DotsIcon(s1, s1.text)
	s1.detail:SetText(W.Color("muted", "the button under the right trackpad"))
	local s2 = Step(2, -112)
	s2.text:SetText("Open " .. W.Color("custom", "Performance"))
	s2.detail:SetText(W.Color("muted", "the lightning icon on the left of the menu"))
	local s3 = Step(3, -150)
	s3.text:SetText("Tap " .. W.Color("custom", "Advanced View"))
	s3.detail:SetText(W.Color("muted", "only if you see it; when it reads Basic View you're there"))
	local s4 = Step(4, -188)
	s4.text:SetText("Change the blue-marked rows")
	page.changes = s4.detail
	page.steps = { s1, s2, s3, s4 }
	page.done = W.Text(page, "GameFontHighlight")
	page.done:SetPoint("TOPLEFT", x, -300)
	page.done:SetWidth(colW)
	page.done:SetJustifyH("LEFT")
	page.done:SetText(W.Color("muted", "Leave the rest as in the picture. Close the menu with the same button: done!"))

	function page.Refresh()
		local key = Window.SelectedKey()
		local active = ns.DB.activePreset
		if active == key then
			page.preset:SetText("Your preset: " .. W.Color("active", ns.Presets[key].label))
		elseif not active then
			page.preset:SetText(W.Color("drift", "No preset yet") .. ": showing " .. ns.Presets[key].label)
		else
			page.preset:SetText("Showing " .. W.Color("custom", ns.Presets[key].label)
				.. W.Color("muted", " (yours is " .. ns.Presets[active].label .. ")"))
		end

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
					lines[#lines + 1] = ("%s  %s"):format(def.label, W.Color("custom", r.text))
				end
			end
		end
		panel:SetHeight(-y + 4)
		page.changes:SetText(table.concat(lines, "\n"))
		page.done:ClearAllPoints()
		page.done:SetPoint("TOPLEFT", page.changes, "BOTTOMLEFT", -26, -16)
	end
end)
