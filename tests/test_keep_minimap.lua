local mock = require("wowmock")

local function FindButton(w, text)
	for _, f in ipairs(w.frames) do
		if f.text == text and f.scripts.OnClick and f.shown ~= false then return f end
	end
	error("no button " .. text)
end

-- Keep / revert -------------------------------------------------------------------

test("doing nothing for 15 seconds reverts the preset", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply performance")
	local d = w:frame("DeckForeverKeep")
	ok(d:IsShown())
	contains(d.question.text, "Keep the Max FPS settings?")
	w:advance(5)
	contains(d.countdown.text, "Reverting in 10 s")
	eq(w:cvar("maxFPS"), "60")
	w:advance(10)
	eq(w:cvar("maxFPS"), "144")
	eq(w:cvar("particleDensity"), "50")
	ok(not d:IsShown())
	eq(w.ns.DB.activePreset, nil)
	eq(w.ns.DB.snapshot, nil, "reverting the first preset drops the snapshot")
end)

test("Keep Settings keeps the preset and stops the countdown", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply battery")
	FindButton(w, "Keep Settings"):Click()
	w:advance(60)
	eq(w:cvar("maxFPS"), "30")
	eq(w.ns.DB.activePreset, "battery")
end)

test("reverting a second preset goes back to the first, not to the originals", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply performance")
	FindButton(w, "Keep Settings"):Click()
	w:slash("apply battery")
	FindButton(w, "Revert"):Click()
	eq(w:cvar("maxFPS"), "60")
	eq(w.ns.DB.activePreset, "performance")
	ok(w.ns.DB.snapshot, "the original snapshot is kept")
	eq(w.ns.DB.snapshot.cvars.maxFPS, "144")
end)

test("restore cancels a pending revert", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply performance")
	w:slash("restore")
	ok(not w:frame("DeckForeverKeep"):IsShown())
	w:advance(30)
	eq(w:cvar("maxFPS"), "144")
	eq(w.ns.DB.activePreset, nil)
end)

test("no keep dialog when nothing changed", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("apply performance")
	FindButton(w, "Keep Settings"):Click()
	w:slash("apply performance")
	ok(not w:frame("DeckForeverKeep"):IsShown())
end)

-- Minimap ---------------------------------------------------------------------------

test("minimap button: left-click toggles the panel, right-click opens the menu", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	local b = w:frame("DeckForeverMinimapButton")
	ok(b, "button created at login")
	b:Click("LeftButton")
	ok(w:frame("DeckForeverWindow"):IsShown())
	b:Click("LeftButton")
	ok(not w:frame("DeckForeverWindow"):IsShown())

	b:Click("RightButton")
	local menu = w:frame("DeckForeverMenu")
	ok(menu:IsShown())
	FindButton(w, "Apply Max Quality"):Click()
	ok(not menu:IsShown(), "menu closes after a choice")
	eq(w:cvar("maxFPS"), "30")
	eq(w.ns.DB.activePreset, "quality")

	b:Click("RightButton")
	FindButton(w, "> Apply Max Quality <")
	local restore
	for _, item in ipairs(menu.items) do
		if item.text == "Restore previous" then restore = item end
	end
	eq(restore.enabled, true)
	eq(#menu.items, 6, "quick actions only")
	FindButton(w, "Open DeckForever"):Click()
	ok(w:frame("DeckForeverWindow"):IsShown())
end)

test("minimap button can be hidden and stays hidden after a relog", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w.ns.ShowTab("options")
	w:frame("DeckForeverWindow").pages.options.minimap:Click()
	ok(not w:frame("DeckForeverMinimapButton"):IsShown())
	eq(w.ns.DB.options.minimap.hide, true)

	local w2 = mock.new({ savedVariables = DeckForeverDB, screen = { 1920, 1080 } })
	w2:login()
	eq(w2:frame("DeckForeverMinimapButton"), nil)
	w2:slash("minimap on")
	ok(w2:frame("DeckForeverMinimapButton"):IsShown())
end)

test("dragging the minimap button saves its angle", function()
	local w = mock.new()
	w:login()
	local b = w:frame("DeckForeverMinimapButton")
	b.scripts.OnDragStart(b)
	w.cursor = { 600, 400 } -- right of the minimap centre (500, 400)
	b.scripts.OnUpdate(b, 0.1)
	b.scripts.OnDragStop(b)
	ok(math.abs(w.ns.DB.options.minimap.angle) < 0.001, "angle " .. w.ns.DB.options.minimap.angle)
end)

-- Calibrate ---------------------------------------------------------------------------

-- Controller ---------------------------------------------------------------------

test("controller: D-pad moves a focus ring, A clicks, B closes, shoulders switch tabs", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w:slash("")
	local win = w:frame("DeckForeverWindow")
	local pad = win.scripts.OnGamePadButtonDown
	ok(pad, "the window listens to the controller")
	eq(pad(win, "PADDDOWN"), false, "handled buttons are not passed to the game")
	local ring = w:frame("DeckForeverFocus")
	ok(ring:IsShown())
	eq(win.gamepad.focus, win.pages.presets.cards.battery.apply, "first button of the page")
	pad(win, "PADDDOWN")
	eq(win.gamepad.focus, win.pages.presets.cards.battery.edit)
	pad(win, "PADDUP")
	eq(win.gamepad.focus, win.pages.presets.cards.battery.apply)
	pad(win, "PAD1")
	ok(w:frame("DeckForeverKeep"):IsShown(), "A clicks the focused button")
	eq(w.ns.DB.activePreset, "battery")
	local keep = w:frame("DeckForeverKeep")
	keep.scripts.OnGamePadButtonDown(keep, "PAD1")
	ok(not keep:IsShown(), "A on the Keep dialog keeps")
	eq(w:cvar("maxFPS"), "30")

	pad(win, "PADRSHOULDER")
	ok(win.pages.customize:IsShown(), "right shoulder: next tab")
	ok(not ring:IsShown(), "focus cleared on a tab change")
	pad(win, "PADLSHOULDER")
	ok(win.pages.presets:IsShown())
	eq(pad(win, "PADRTRIGGER"), true, "unused buttons go to the game")
	pad(win, "PAD2")
	ok(not win:IsShown(), "B closes the window")
	ok(not ring:IsShown())
end)

test("controller: left/right on a stepper steps it; B on Keep reverts; menu and prompt navigate", function()
	local w = mock.new({ screen = { 1920, 1080 } })
	w:login()
	w.ns.ShowTab("options")
	local win = w:frame("DeckForeverWindow")
	local pad = win.scripts.OnGamePadButtonDown
	local O = win.pages.options
	local seen = {}
	for _ = 1, 40 do
		pad(win, "PADDDOWN")
		if win.gamepad.focus == O.minutes.next then break end
		seen[#seen + 1] = win.gamepad.focus and win.gamepad.focus.text or "?"
	end
	eq(win.gamepad.focus, O.minutes.next, "reaches the stepper (visited: " .. table.concat(seen, ", ") .. ")")
	pad(win, "PADDRIGHT")
	eq(w.ns.DB.options.reminderMinutes, 105, "right steps the stepper")
	pad(win, "PADDLEFT")
	eq(w.ns.DB.options.reminderMinutes, 90)
	eq(win.gamepad.focus, O.minutes.next, "focus stays on the stepper")

	w:slash("apply balanced")
	local keep = w:frame("DeckForeverKeep")
	keep.scripts.OnGamePadButtonDown(keep, "PAD2")
	ok(not keep:IsShown())
	eq(w.ns.DB.activePreset, nil, "B reverts")

	w:frame("DeckForeverMinimapButton"):Click("RightButton")
	local menu = w:frame("DeckForeverMenu")
	menu.scripts.OnGamePadButtonDown(menu, "PADDDOWN")
	eq(menu.gamepad.focus, menu.items[1])
	menu.scripts.OnGamePadButtonDown(menu, "PAD2")
	ok(not menu:IsShown())

	local w2 = mock.new()
	w2:login()
	w2:advance(3)
	local p = w2:frame("DeckForeverPrompt")
	p.scripts.OnGamePadButtonDown(p, "PAD1")
	ok(not p:IsShown(), "A on the prompt takes the recommended preset")
	eq(w2.ns.DB.activePreset, "battery")
end)
