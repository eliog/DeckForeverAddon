-- GamePad: controller navigation for the addon's frames, the way Forever's own Gamepad UI works.
-- D-pad moves a focus ring between buttons, A clicks, B closes (or the frame's own "back"),
-- shoulders switch tabs. Buttons the frame does not handle are passed on to the game.
-- Frames opt in with ns.GamePad.Attach(frame, candidates, opts).
local _, ns = ...

local G = {}
ns.GamePad = G

local ring

local function Ring()
	if ring then return ring end
	ring = CreateFrame("Frame", "DeckForeverFocus", UIParent)
	ring:SetFrameStrata("TOOLTIP")
	ring:Hide()
	local function Line(a, b, w, h)
		local t = ring:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(1, 0.82, 0, 0.9)
		t:SetPoint(a)
		t:SetPoint(b)
		if w then t:SetWidth(w) else t:SetHeight(h) end
	end
	Line("TOPLEFT", "TOPRIGHT", nil, 3)
	Line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 3)
	Line("TOPLEFT", "BOTTOMLEFT", 3, nil)
	Line("TOPRIGHT", "BOTTOMRIGHT", 3, nil)
	return ring
end

local function Usable(b)
	return b and b:IsShown() and (not b.IsEnabled or b:IsEnabled() ~= false)
end

local function Center(b)
	local x, y = b:GetCenter()
	if type(x) == "number" and type(y) == "number" then return x, y end
end

-- The best candidate in a direction: closest ahead, with sideways offset penalised.
-- Without positions (or nothing ahead), the next in list order.
local function Pick(list, from, dir)
	if not from then return list[1] end
	local fx, fy = Center(from)
	local best, bestScore
	if fx then
		for _, b in ipairs(list) do
			if b ~= from then
				local x, y = Center(b)
				if x then
					local ahead, side
					if dir == "up" then ahead, side = y - fy, math.abs(x - fx)
					elseif dir == "down" then ahead, side = fy - y, math.abs(x - fx)
					elseif dir == "left" then ahead, side = fx - x, math.abs(y - fy)
					else ahead, side = x - fx, math.abs(y - fy) end
					if ahead > 2 then
						local score = ahead + side * 2.5
						if not bestScore or score < bestScore then best, bestScore = b, score end
					end
				end
			end
		end
	end
	if best then return best end
	local i
	for k, b in ipairs(list) do if b == from then i = k end end
	if not i then return list[1] end
	local step = (dir == "down" or dir == "right") and 1 or -1
	return list[((i - 1 + step) % #list) + 1]
end

local DIRS = { PADDUP = "up", PADDDOWN = "down", PADDLEFT = "left", PADDRIGHT = "right" }

-- candidates(): the buttons the D-pad can reach, in reading order. opts.onBack (B; default
-- hides the frame), opts.onTab(dir) (shoulders), opts.default (A with nothing focused).
function G.Attach(frame, candidates, opts)
	opts = opts or {}
	local state = { focus = nil }
	frame.gamepad = state

	function state.Focus(b)
		state.focus = b
		local r = Ring()
		r:ClearAllPoints()
		if b then
			r:SetPoint("TOPLEFT", b, "TOPLEFT", -3, 3)
			r:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
			r:Show()
		else
			r:Hide()
		end
	end

	local function List()
		local list = {}
		for _, b in ipairs(candidates()) do
			if Usable(b) and not rawget(b, "navSkip") then list[#list + 1] = b end
		end
		return list
	end

	local function Press(button)
		local dir = DIRS[button]
		if dir then
			local f = state.focus
			-- left/right on a stepper steps it instead of leaving it
			local stepper = f and rawget(f, "stepper")
			if stepper and (dir == "left" or dir == "right") then
				local b = dir == "left" and stepper.prev or stepper.next
				if Usable(b) then b:Click() end
				return true
			end
			local list = List()
			if #list == 0 then return true end
			if f and not Usable(f) then f = nil end
			state.Focus(Pick(list, f, dir))
			return true
		elseif button == "PAD1" then
			local b = state.focus
			if Usable(b) then b:Click()
			elseif opts.default and Usable(opts.default()) then opts.default():Click()
			else state.Focus(List()[1]) end
			return true
		elseif button == "PAD2" then
			if opts.onBack then opts.onBack() else frame:Hide() end
			return true
		elseif (button == "PADLSHOULDER" or button == "PADRSHOULDER") and opts.onTab then
			opts.Blur()
			opts.onTab(button == "PADLSHOULDER" and -1 or 1)
			return true
		end
		return false
	end

	function opts.Blur() state.Focus(nil) end
	state.Blur = opts.Blur

	if frame.EnableGamePadButton then frame:EnableGamePadButton(true) end
	frame:SetScript("OnGamePadButtonDown", function(self, button)
		local handled = Press(button)
		-- let the game have the buttons we did not use (the call is blocked in combat)
		if not InCombatLockdown() and self.SetPropagateKeyboardInput then
			pcall(self.SetPropagateKeyboardInput, self, not handled)
		end
		return not handled
	end)
	local onHide = frame:GetScript("OnHide")
	frame:SetScript("OnHide", function(self, ...)
		if onHide then onHide(self, ...) end
		if state.focus then state.Focus(nil) end
	end)
end
