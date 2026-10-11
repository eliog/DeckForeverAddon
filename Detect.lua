-- Detect: Steam Deck heuristic. Wine reports Windows, so look at the screen and the Gamepad UI.
local _, ns = ...

local DECK_W, DECK_H = 1280, 800

-- Returns isDeck, reasons. The screen size decides; the Gamepad UI only adds to the reasons.
-- (GamePadEnable is no signal: it defaults to 1 in Forever.)
function ns.LooksLikeDeck()
	local reasons = {}
	local w, h
	if GetPhysicalScreenSize then w, h = GetPhysicalScreenSize() end
	local screen = w == DECK_W and h == DECK_H
	if screen then table.insert(reasons, "1280x800 screen") end

	if C_CVar.GetCVar("InputDeviceInterfaceStyle") == "1" then table.insert(reasons, "Gamepad UI on") end

	return screen and true or false, reasons
end
