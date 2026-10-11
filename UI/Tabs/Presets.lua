-- Presets tab: one card per preset with its key numbers, an Apply button, and shortcuts to
-- customize it or see its Steam Deck settings.
local _, ns = ...

local W = ns.Widgets
local CARD_W, CARD_H, GAP = 166, 344, 8

-- "Max FPS 40", "Render Scale 85%", "Lighting Fair", from the effective (customized) values
local KEY_NUMBERS = {
	{ cvar = "maxFPS", label = "Max FPS" },
	{ cvar = "RenderScale", label = "Render Scale" },
	{ cvar = "graphicsLightMode", label = "Lighting" },
	{ cvar = "graphicsShadowQuality", label = "Shadows" },
}

local function BuildCard(page, key, x)
	local preset = ns.Presets[key]
	local card = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
	card:SetSize(CARD_W, CARD_H)
	card:SetPoint("TOPLEFT", x, -8)

	card.title = W.Text(card, "GameFontNormalLarge")
	card.title:SetPoint("TOPLEFT", 14, -14)
	card.badge = W.Text(card, "GameFontNormal", W.Color("active", "ACTIVE"))
	card.badge:SetPoint("TOPRIGHT", -10, -16)
	card.desc = W.Text(card, "GameFontHighlightSmall", preset.desc)
	card.desc:SetPoint("TOPLEFT", 14, -38)
	card.desc:SetWidth(CARD_W - 24)
	card.desc:SetJustifyH("LEFT")

	card.numbers = {}
	for i in ipairs(KEY_NUMBERS) do
		local fs = W.Text(card, "GameFontHighlight")
		fs:SetPoint("TOPLEFT", 14, -66 - i * 20)
		card.numbers[i] = fs
	end
	local hours = ns.HoursText(key)
	card.hours = W.Text(card, "GameFontHighlightSmall",
		W.Color("muted", hours and ("Deck OLED:\n" .. hours) or "Deck OLED: not measured yet"))
	card.hours:SetPoint("TOPLEFT", 14, -170)
	card.hours:SetWidth(CARD_W - 24)
	card.hours:SetJustifyH("LEFT")
	card.drift = W.Text(card, "GameFontHighlightSmall")
	card.drift:SetPoint("TOPLEFT", 14, -204)

	card.apply = W.Button(card, "Apply", CARD_W - 24, 40, function() ns.ApplyPreset(key) end)
	card.apply:SetPoint("TOP", 0, -222)
	card.edit = W.Button(card, "Customize", CARD_W - 24, 32, function() ns.ShowTab("customize", key) end)
	card.edit:SetPoint("TOP", 0, -266)
	card.deck = W.Button(card, "Steam Deck", CARD_W - 24, 32, function() ns.ShowTab("deck", key) end)
	card.deck:SetPoint("TOP", 0, -302)

	function card.Refresh()
		local active = ns.DB.activePreset == key
		card.title:SetText(preset.label .. (ns.HasOverrides(key) and W.Color("custom", "*") or ""))
		card.badge:SetShown(active)
		for i, n in ipairs(KEY_NUMBERS) do
			local overridden = ns.GetOverrides(key)[n.cvar] ~= nil
			local text = ns.LevelText(n.cvar, ns.EffectiveValue(key, n.cvar))
			card.numbers[i]:SetText(n.label .. "  " .. (overridden and W.Color("custom", text) or text))
		end
		local drift = active and ns.PresetDrift(key) or 0
		card.drift:SetText(drift > 0 and W.Color("drift", ("%d changed since applied"):format(drift)) or "")
		card.apply:SetText(active and "Re-apply" or "Apply")
	end
	return card
end

ns.Window.RegisterTab("presets", "Presets", function(page)
	page.cards = {}
	for i, key in ipairs(ns.Presets.order) do
		page.cards[key] = BuildCard(page, key, 8 + (i - 1) * (CARD_W + GAP))
	end
	page.help = W.Text(page, "GameFontHighlightSmall",
		"After applying, you have 15 seconds to keep the new settings, or they go back on their own.\n"
		.. "Your own settings are saved before the first preset: Restore previous brings them back.\n"
		.. "UI scale is not part of the presets: set it once under Tools (about 75% suits the 7-inch screen).")
	page.help:SetPoint("TOPLEFT", 12, -CARD_H - 20)
	page.help:SetJustifyH("LEFT")

	function page.Refresh()
		for _, card in pairs(page.cards) do card.Refresh() end
	end
end)
