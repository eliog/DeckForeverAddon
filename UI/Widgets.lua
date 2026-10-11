-- Widgets: shared building blocks for the window. Sized for the Steam Deck: controls are at
-- least 36 high, nothing is hover-only, no dropdowns or modal popups.
local _, ns = ...

local W = {}
ns.Widgets = W

W.COLOR = {
	active = "ff60ff60",  -- the active preset
	custom = "ffffd100",  -- customized values, "*"
	drift = "ffffa040",   -- changed since the preset was applied
	pending = "ffffff60", -- waiting for combat to end
	muted = "ffaaaaaa",   -- your own settings, secondary info
}

function W.Color(key, text)
	return "|c" .. W.COLOR[key] .. text .. "|r"
end

function W.Text(parent, font, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
	if text then fs:SetText(text) end
	return fs
end

-- every button is reachable with a controller (UI/GamePad.lua); navParent finds its page
W.buttons = {}
function W.Button(parent, text, w, h, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, h or 36)
	b:SetText(text)
	if onClick then b:SetScript("OnClick", onClick) end
	b.navParent = parent
	W.buttons[#W.buttons + 1] = b
	return b
end

-- The page (or window) a button belongs to, following navParent up.
function W.NavRoot(b)
	local f = b
	while f and not rawget(f, "isNavRoot") do
		f = rawget(f, "navParent") or (f.GetParent and f:GetParent()) or nil
	end
	return f
end

-- A row of buttons where one is selected (highlight locked). items: { { key =, label = } }.
-- Returns { buttons = { [key] = button }, Select = function(key) }.
function W.Segmented(parent, items, w, h, onSelect)
	local seg = { buttons = {} }
	for i, item in ipairs(items) do
		local b = W.Button(parent, item.label, w, h, function() onSelect(item.key) end)
		b.key = item.key
		seg.buttons[item.key] = b
		seg[i] = b
	end
	function seg.Select(key)
		for k, b in pairs(seg.buttons) do
			if k == key then b:LockHighlight() else b:UnlockHighlight() end
		end
	end
	return seg
end

-- Toggle button reading "Label: On" / "Label: Off". get() returns the state, set(state) changes it.
function W.Toggle(parent, label, w, get, set)
	local b = W.Button(parent, label, w, 36)
	function b.Refresh()
		b:SetText(("%s: %s"):format(label, get() and W.Color("active", "On") or W.Color("muted", "Off")))
	end
	b:SetScript("OnClick", function()
		set(not get())
		b.Refresh()
	end)
	return b
end

-- < text > stepper. getText() returns the label; onStep(dir) changes the value.
function W.Stepper(parent, w, getText, onStep)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(w, 36)
	f.navParent = parent
	f.prev = W.Button(f, "<", 40, 34, function() onStep(-1) f.Refresh() end)
	f.prev:SetPoint("LEFT", 0, 0)
	f.next = W.Button(f, ">", 40, 34, function() onStep(1) f.Refresh() end)
	f.next:SetPoint("RIGHT", 0, 0)
	-- the controller focuses the stepper as one thing: D-pad left/right step it
	f.prev.navSkip, f.next.stepper, f.prev.stepper = true, f, f
	f.label = W.Text(f, "GameFontHighlight")
	f.label:SetPoint("CENTER", 0, 0)
	f.label:SetWidth(w - 90)
	function f.Refresh() f.label:SetText(getText()) end
	return f
end

-- Preset selector items in preset order.
function W.PresetItems()
	local items = {}
	for _, key in ipairs(ns.Presets.order) do
		items[#items + 1] = { key = key, label = ns.Presets[key].label }
	end
	return items
end
