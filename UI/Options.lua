-- Options: a page under the game's Settings > AddOns that opens the DeckForever window.
-- All options live in the window's Tools tab, so there is one place to change them.
local _, ns = ...

local W = ns.Widgets

local function Register()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local f = CreateFrame("Frame")
	f.title = W.Text(f, "GameFontNormalHuge", "DeckForever")
	f.title:SetPoint("TOPLEFT", 16, -16)
	f.text = W.Text(f, "GameFontHighlight",
		"Steam Deck presets for World of Warcraft: Forever. Presets, customizing, Steam Deck settings\n"
		.. "and options are all in the DeckForever window.")
	f.text:SetPoint("TOPLEFT", 16, -52)
	f.text:SetJustifyH("LEFT")
	f.open = W.Button(f, "Open DeckForever", 200, 40, function()
		if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel) end
		ns.ShowPanel()
	end)
	f.open:SetPoint("TOPLEFT", 16, -100)
	local category = Settings.RegisterCanvasLayoutCategory(f, "DeckForever")
	Settings.RegisterAddOnCategory(category)
	ns.optionsCategory = category
end

ns.On("PLAYER_LOGIN", function() pcall(Register) end)
