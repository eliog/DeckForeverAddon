-- Minimap: draggable button (left-click: panel, right-click: menu) and its menu.
-- Library-free; the menu is a plain frame of large buttons, easy to hit with the gamepad cursor.
local _, ns = ...

local button, menu
local atan2 = math.atan2 or math.atan -- Lua 5.1 (the client) has atan2

-- Menu ---------------------------------------------------------------------------

local MENU_W, ITEM_H = 220, 42

-- Quick actions only; everything else is in the window.
local function MenuItems()
	local items = {}
	for _, key in ipairs(ns.Presets.order) do
		local p = ns.Presets[key]
		local text = "Apply " .. p.label
		if ns.DB.activePreset == key then text = "> " .. text .. " <" end
		items[#items + 1] = { text = text, fn = function() ns.ApplyPreset(key) end }
	end
	items[#items + 1] = { text = "Restore previous", fn = ns.RestoreSnapshot, disabled = not ns.HasSnapshot() }
	items[#items + 1] = { text = "Open DeckForever", fn = ns.ShowPanel }
	return items
end

local function BuildMenu()
	local f = CreateFrame("Frame", "DeckForeverMenu", UIParent, "BasicFrameTemplateWithInset")
	f:SetFrameStrata("DIALOG")
	f:EnableMouse(true)
	table.insert(UISpecialFrames, "DeckForeverMenu")
	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.title:SetPoint("TOP", 0, -5)
	f.title:SetText("DeckForever")
	f.items = {}
	ns.GamePad.Attach(f, function() return f.items end)
	return f
end

local function ShowMenu()
	if not menu then menu = BuildMenu() end
	local items = MenuItems()
	for i, item in ipairs(items) do
		local b = menu.items[i]
		if not b then
			b = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
			b:SetSize(MENU_W - 20, ITEM_H - 2)
			b:SetPoint("TOP", menu, "TOP", 0, -28 - (i - 1) * ITEM_H)
			menu.items[i] = b
		end
		b:SetText(item.text)
		b:SetEnabled(not item.disabled)
		b:SetScript("OnClick", function()
			menu:Hide()
			item.fn()
		end)
		b:Show()
	end
	for i = #items + 1, #menu.items do menu.items[i]:Hide() end
	menu:SetSize(MENU_W, 36 + #items * ITEM_H)
	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT", 0, 0)
	menu:Show()
end

function ns.ToggleMenu()
	if menu and menu:IsShown() then menu:Hide() else ShowMenu() end
end

-- Button ---------------------------------------------------------------------------

local function UpdatePosition()
	local angle = math.rad(ns.DB.options.minimap.angle)
	local r = Minimap:GetWidth() / 2 + 8
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function OnDragUpdate()
	local mx, my = Minimap:GetCenter()
	local cx, cy = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	ns.DB.options.minimap.angle = math.deg(atan2(cy / scale - my, cx / scale - mx))
	UpdatePosition()
end

local function Build()
	local b = CreateFrame("Button", "DeckForeverMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetPoint("TOPLEFT", 7, -5)

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
	icon:SetPoint("TOPLEFT", 7, -6)

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	b:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then
			ns.ToggleMenu()
		else
			if menu then menu:Hide() end
			ns.TogglePanel()
		end
	end)
	b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("DeckForever")
		local active = ns.DB.activePreset and ns.GetPreset(ns.DB.activePreset).label or "your own settings"
		GameTooltip:AddLine("Active: " .. active, 1, 1, 1)
		GameTooltip:AddLine("Left-click: panel. Right-click: menu. Drag: move.", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return b
end

function ns.SetMinimapShown(shown)
	ns.DB.options.minimap.hide = not shown
	if shown then
		if not button then button = Build() end
		UpdatePosition()
		button:Show()
	elseif button then
		button:Hide()
		ns.Print("Minimap button hidden. Turn it back on in DeckForever > Tools (/deckforever).")
	end
end

ns.On("PLAYER_LOGIN", function()
	if not ns.DB.options.minimap.hide then ns.SetMinimapShown(true) end
end)
