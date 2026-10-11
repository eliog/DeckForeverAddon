-- Prompt: once per account, offer the Deck preset on a client that looks like a Deck.
-- Never silent: the user picks, and the decision is stored so we never ask again.
local _, ns = ...

local WIDTH, PREVIEW_LINES = 440, 12
local prompt

local function PreviewText(key)
	local rows = ns.PreviewPreset(key)
	local lines, changes, twins = {}, 0, 0
	for _, r in ipairs(rows) do
		local m = ns.CVarMeta[r.name]
		if r.status == "change" and m and m.twinOf then
			twins = twins + 1 -- raid twins mirror the lines above; listing them hides the rest
		elseif r.status == "change" then
			changes = changes + 1
			if changes <= PREVIEW_LINES then
				lines[#lines + 1] = ("%s: %s -> %s"):format(r.name, tostring(r.current), r.target)
			end
		end
	end
	if changes > PREVIEW_LINES then
		lines[#lines + 1] = ("... and %d more (/deckforever preview %s)"):format(changes - PREVIEW_LINES, key)
	end
	local header = ("%d settings will change"):format(changes)
	if twins > 0 then header = header .. (", plus %d raid/battleground twins to match"):format(twins) end
	return header .. ":\n" .. table.concat(lines, "\n")
end

local function MakeButton(parent, text, x, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(130, 36)
	b:SetPoint("BOTTOM", parent, "BOTTOM", x, 14)
	b:SetText(text)
	b:SetScript("OnClick", function()
		parent:Hide()
		onClick()
	end)
	parent.choices[#parent.choices + 1] = b
	return b
end

local function Build()
	local f = CreateFrame("Frame", "DeckForeverPrompt", UIParent, "BasicFrameTemplateWithInset")
	f.choices = {}
	f:SetFrameStrata("DIALOG")
	f:SetSize(WIDTH, 400)
	f:SetPoint("CENTER")
	f:EnableMouse(true)
	-- not in UISpecialFrames: an Escape meant for something else (skipping the intro
	-- cinematic) must not dismiss it. Any hide (a button or the close X) is the decision.
	f:SetScript("OnHide", function() ns.DB.promptedOnce = true end)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.title:SetPoint("TOP", 0, -5)
	f.title:SetText("DeckForever")

	f.question = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.question:SetPoint("TOP", 0, -36)
	f.question:SetWidth(WIDTH - 30)
	f.question:SetText("Apply the Steam Deck preset?")

	f.why = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.why:SetPoint("TOP", f.question, "BOTTOM", 0, -6)
	f.why:SetWidth(WIDTH - 30)

	f.preview = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.preview:SetPoint("TOPLEFT", 20, -90)
	f.preview:SetWidth(WIDTH - 40)
	f.preview:SetJustifyH("LEFT")

	MakeButton(f, "Battery", -140, function() ns.ApplyPreset("battery") end)
	MakeButton(f, "Balanced", 0, function() ns.ApplyPreset("balanced") end)
	MakeButton(f, "Not now", 140, function()
		ns.Print("Open the presets any time with /deckforever.")
	end)
	ns.GamePad.Attach(f, function() return f.choices end,
		{ onBack = function() f.choices[3]:Click() end, default = function() return f.choices[1] end })
	return f
end

function ns.ShowPrompt()
	if not prompt then prompt = Build() end
	local _, reasons = ns.LooksLikeDeck()
	prompt.why:SetText(#reasons > 0 and ("Detected: " .. table.concat(reasons, ", ")) or "")
	prompt.preview:SetText(PreviewText("battery"))
	prompt:Show()
end

-- First login --------------------------------------------------------------------
-- A new character's first login plays the intro cinematic, which can start a moment after
-- PLAYER_ENTERING_WORLD. Wait a few seconds, then wait for any cinematic or movie to end.

local DELAY, AFTER_CINEMATIC = 3, 2
local pending = false

local function InCutscene()
	return (InCinematic and InCinematic()) or (MovieFrame and MovieFrame:IsShown()) or false
end

local function TryShow()
	if not pending or ns.DB.promptedOnce then return end
	if InCutscene() then return end -- CINEMATIC_STOP / STOP_MOVIE retries
	pending = false
	ns.ShowPrompt()
end

local function AfterCutscene()
	if pending then C_Timer.After(AFTER_CINEMATIC, TryShow) end
end

ns.On("CINEMATIC_STOP", AfterCutscene)
ns.On("STOP_MOVIE", AfterCutscene)

ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin)
	if not isInitialLogin or ns.DB.promptedOnce or not ns.LooksLikeDeck() then return end
	pending = true
	C_Timer.After(DELAY, TryShow)
end)
