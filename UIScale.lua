-- UIScale: the uiScale CVars are locked in Forever (GetCVarInfo reports them locked and SetCVar
-- does not take), but UIParent's own scale can be set directly, as the big UI addons do. The
-- game resets UIParent when the display or its scale setting changes, so it is re-applied then.
-- Only active once the user picks a value; "Game default" leaves everything alone.
local _, ns = ...

ns.UI_SCALE_STEPS = { 0.64, 0.7, 0.75, 0.8, 0.85, 0.9, 1.0 }

local applying = false

function ns.ApplyUIScale()
	local s = ns.DB.options.uiScale
	if not s or applying then return end
	if InCombatLockdown() then
		ns.RunWhenSafe("uiscale", ns.ApplyUIScale)
		return
	end
	applying = true
	-- the CVars first: if they take, the game keeps the value itself
	pcall(C_CVar.SetCVar, "useUiScale", "1")
	pcall(C_CVar.SetCVar, "uiScale", ns.FormatValue(s))
	local took = C_CVar.GetCVar("useUiScale") == "1"
		and math.abs((tonumber(C_CVar.GetCVar("uiScale")) or 0) - s) < 0.005
	if not took then UIParent:SetScale(s) end
	ns.uiScaleVia = took and "cvar" or "frame"
	applying = false
end

-- nil = game default (stop managing it; the game's own value returns after a reload)
function ns.SetUIScale(s)
	ns.DB.options.uiScale = s
	if s then
		ns.ApplyUIScale()
		ns.Print("UI scale %d%% (%s). Reload UI if parts of the interface look misplaced.",
			math.floor(s * 100 + 0.5), ns.uiScaleVia == "cvar" and "game setting" or "scaled by DeckForever")
	else
		ns.Print("UI scale back to the game's own setting after Reload UI.")
	end
	ns.Changed()
end

ns.On("PLAYER_LOGIN", ns.ApplyUIScale)
ns.On("UI_SCALE_CHANGED", ns.ApplyUIScale)
ns.On("DISPLAY_SIZE_CHANGED", ns.ApplyUIScale)
