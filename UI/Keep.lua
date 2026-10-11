-- Keep: after a preset is applied, 15 seconds to keep it or go back.
-- If the screen becomes unusable, doing nothing reverts.
local _, ns = ...

local SECONDS = 15
local dialog, ticker, undo, remaining

local function Stop()
	if ticker then ticker:Cancel() end
	ticker, undo = nil, nil
	if dialog then dialog:Hide() end
end

-- Forget the pending revert (another write, e.g. Restore, supersedes it).
function ns.CancelKeep() Stop() end

function ns.KeepPending() return undo ~= nil end

function ns.KeepSettings()
	Stop()
end

-- Puts back the settings from before the last apply.
function ns.RevertLastApply()
	local u = undo
	Stop()
	if not u then return end
	ns.RunWhenSafe("settings", function()
		local res = ns.WriteCVars(ns.EntriesFrom(u.cvars), { noRangeCheck = true })
		ns.DB.activePreset = u.activePreset
		-- reverting the first preset puts back exactly the snapshot, so it is no longer needed
		if u.tookSnapshot and #res.failed == 0 then ns.DB.snapshot = nil end
		ns.ReportResult("Reverted", res)
		ns.Changed()
	end)
end

local function UpdateText()
	dialog.countdown:SetText(("Reverting in %d s"):format(remaining))
end

local function Build()
	local f = CreateFrame("Frame", "DeckForeverKeep", UIParent, "BasicFrameTemplateWithInset")
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetSize(340, 150)
	f:SetPoint("TOP", 0, -120)
	f:EnableMouse(true)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.title:SetPoint("TOP", 0, -5)
	f.title:SetText("DeckForever")

	f.question = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.question:SetPoint("TOP", 0, -34)
	f.question:SetWidth(310)

	f.countdown = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.countdown:SetPoint("TOP", f.question, "BOTTOM", 0, -8)

	f.keep = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.keep:SetSize(140, 36)
	f.keep:SetPoint("BOTTOM", -75, 14)
	f.keep:SetText("Keep Settings")
	f.keep:SetScript("OnClick", ns.KeepSettings)

	f.revert = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.revert:SetSize(140, 36)
	f.revert:SetPoint("BOTTOM", 75, 14)
	f.revert:SetText("Revert")
	f.revert:SetScript("OnClick", ns.RevertLastApply)
	ns.GamePad.Attach(f, function() return { f.keep, f.revert } end,
		{ onBack = ns.RevertLastApply, default = function() return f.keep end })

	-- the close X keeps, like the Keep button
	f:SetScript("OnHide", function() if undo then ns.KeepSettings() end end)
	return f
end

function ns.OfferKeep(label, undoState)
	Stop()
	if not dialog then dialog = Build() end
	undo = undoState
	remaining = SECONDS
	dialog.question:SetText(("Keep the %s settings?"):format(label))
	UpdateText()
	dialog:Show()
	ticker = C_Timer.NewTicker(1, function()
		remaining = remaining - 1
		if remaining <= 0 then
			ns.RevertLastApply()
		else
			UpdateText()
		end
	end)
end
