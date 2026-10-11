-- Window: the single DeckForever window. Header status line, tab strip, a content inset with
-- one page per tab, and a fixed footer (Restore previous, combat status, Reload UI, Close).
-- Tabs register themselves (UI/Tabs/*.lua); pages are all built with the window.
local _, ns = ...

local W = ns.Widgets
local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 720, 560
local TAB_W = 126 -- five tabs across
local ICON = "Interface\\AddOns\\DeckForever\\Media\\icon"

local tabs = {}
local frame, current, syncing, selectedKey

-- tab registry ----------------------------------------------------------------------------

-- build(page) fills the page; it may set page.Refresh.
-- Companion addons may register tabs too, before the window is first opened.
function Window.RegisterTab(name, label, build)
	tabs[#tabs + 1] = { name = name, label = label, build = build }
end

local function ActiveTabs() return tabs end

local function TabId(name)
	for i, t in ipairs(ActiveTabs()) do
		if t.name == name then return i end
	end
end

-- selected preset, shared by the Customize and Steam Deck tabs
function Window.SelectedKey()
	return selectedKey or ns.DB.activePreset or ns.Presets.order[1]
end

function Window.SetSelectedKey(key)
	selectedKey = key
	Window.Refresh()
end

-- header / footer ------------------------------------------------------------------------

local function StatusText()
	local fps = GetFramerate()
	local cap = C_CVar.GetCVar("useMaxFPS") == "1" and C_CVar.GetCVar("maxFPS")
	local parts = { ("%.0f fps%s"):format(fps, cap and (" (cap " .. cap .. ")") or "") }
	local active = ns.DB.activePreset
	if active then
		local label = ns.Presets[active].label .. (ns.HasOverrides(active) and "*" or "")
		local s = "Active: " .. W.Color("active", label)
		local drift = ns.PresetDrift(active)
		if drift > 0 then s = s .. " " .. W.Color("drift", ("(%d changed since)"):format(drift)) end
		parts[#parts + 1] = s
	else
		parts[#parts + 1] = "Active: " .. W.Color("muted", "your own settings")
	end
	return table.concat(parts, "   |   ")
end

function Window.Refresh()
	if not frame or not frame:IsShown() then return end
	frame.status:SetText(StatusText())
	frame.restore:SetEnabled(ns.HasSnapshot())
	frame.pending:SetText(ns.HasQueued() and W.Color("pending", "Waiting for combat to end") or "")
	for _, page in pairs(frame.pages) do
		if page.Refresh then page.Refresh() end
	end
end

-- tabs -------------------------------------------------------------------------------------

function Window.SelectTab(name)
	if not TabId(name) then name = ActiveTabs()[1].name end
	if frame and rawget(frame, "gamepad") and current ~= name then frame.gamepad.Blur() end
	current = name
	ns.DB.options.window.tab = name
	for tabName, page in pairs(frame.pages) do
		if tabName == name then page:Show() else page:Hide() end
	end
	if frame.tabSystem then
		syncing = true
		pcall(frame.tabSystem.SetTab, frame.tabSystem, TabId(name))
		syncing = false
	else
		frame.tabButtons.Select(name)
	end
	Window.Refresh()
end

function Window.CurrentTab() return current end

-- Blizzard's TabSystemTemplate (confirmed in Forever); plain buttons if it is missing.
local function BuildTabs(f)
	local good, ts = pcall(CreateFrame, "Frame", nil, f, "TabSystemTemplate")
	if good and ts and ts.AddTab then
		ts:SetPoint("TOPLEFT", 60, -54)
		for i, t in ipairs(ActiveTabs()) do
			ts:AddTab(t.label)
			local b = ts.GetTabButton and ts:GetTabButton(i)
			if b and b.SetTabWidth then b:SetTabWidth(TAB_W) end
		end
		if ts.MarkDirty then ts:MarkDirty() end
		ts:SetTabSelectedCallback(function(id)
			local t = ActiveTabs()[id]
			if not syncing and t then Window.SelectTab(t.name) end
			return false
		end)
		f.tabSystem = ts
	else
		local items = {}
		for _, t in ipairs(ActiveTabs()) do items[#items + 1] = { key = t.name, label = t.label } end
		f.tabButtons = W.Segmented(f, items, TAB_W, 36, Window.SelectTab)
		for i, b in ipairs(f.tabButtons) do b:SetPoint("TOPLEFT", 60 + (i - 1) * (TAB_W + 4), -54) end
	end
end

local function SavePosition(f)
	local point, _, relPoint, x, y = f:GetPoint()
	ns.DB.options.window.point = { point, relPoint, x, y }
end

local function Build()
	local opts = ns.DB.options.window
	local good, f = pcall(CreateFrame, "Frame", "DeckForeverWindow", UIParent, "PortraitFrameTemplate")
	if not good then
		f = CreateFrame("Frame", "DeckForeverWindow", UIParent, "BasicFrameTemplateWithInset")
	end
	f:SetSize(WIDTH, HEIGHT)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetScale(opts.scale or 1.15)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition(self)
	end)
	if opts.point then
		f:SetPoint(opts.point[1], UIParent, opts.point[2], opts.point[3], opts.point[4])
	else
		f:SetPoint("CENTER")
	end
	table.insert(UISpecialFrames, "DeckForeverWindow")

	if good and f.SetTitle then
		f:SetTitle("DeckForever")
		if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, ICON) end
	else
		f.titleText = W.Text(f, "GameFontHighlight", "DeckForever")
		f.titleText:SetPoint("TOP", 0, -5)
	end

	f.status = W.Text(f, "GameFontHighlight")
	f.status:SetPoint("TOPLEFT", 64, -32)
	f.status:SetPoint("TOPRIGHT", -16, -32)
	f.status:SetJustifyH("LEFT")

	BuildTabs(f)

	local inset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
	inset:SetPoint("TOPLEFT", 10, -94)
	inset:SetPoint("BOTTOMRIGHT", -8, 52)
	f.inset = inset

	f.isNavRoot = true
	f.pages = {}
	for _, t in ipairs(ActiveTabs()) do
		local page = CreateFrame("Frame", nil, inset)
		page.isNavRoot = true
		page:SetPoint("TOPLEFT", 4, -4)
		page:SetPoint("BOTTOMRIGHT", -4, 4)
		t.build(page)
		page:Hide()
		f.pages[t.name] = page
	end

	f.restore = W.Button(f, "Restore previous", 180, 36, function() ns.RestoreSnapshot() end)
	f.restore:SetPoint("BOTTOMLEFT", 12, 10)
	f.pending = W.Text(f, "GameFontHighlight")
	f.pending:SetPoint("BOTTOM", -40, 20)
	f.close = W.Button(f, "Close", 100, 36, function() f:Hide() end)
	f.close:SetPoint("BOTTOMRIGHT", -12, 10)
	f.reload = W.Button(f, "Reload UI", 120, 36, function() ReloadUI() end)
	f.reload:SetPoint("RIGHT", f.close, "LEFT", -8, 0)

	-- controller: D-pad over the current page's buttons, then the footer; shoulders change tabs
	ns.GamePad.Attach(f, function()
		local list, page = {}, f.pages[current]
		for _, b in ipairs(W.buttons) do
			local root = W.NavRoot(b)
			if root == page then list[#list + 1] = b end
		end
		for _, b in ipairs(W.buttons) do
			if W.NavRoot(b) == f and b ~= f.close then list[#list + 1] = b end
		end
		list[#list + 1] = f.close
		return list
	end, {
		onTab = function(dir)
			local id = TabId(current) or 1
			local n = #ActiveTabs()
			Window.SelectTab(ActiveTabs()[((id - 1 + dir) % n) + 1].name)
		end,
	})

	local elapsed = 0
	f:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed >= 0.5 then
			elapsed = 0
			f.status:SetText(StatusText())
		end
	end)
	f:SetScript("OnShow", Window.Refresh)
	return f
end

-- public -----------------------------------------------------------------------------------

-- Shows the window on a tab (default: the last one used), optionally selecting a preset.
function ns.ShowTab(name, key)
	if not frame then frame = Build() end
	key = key and key:lower()
	if key and ns.GetPreset(key) then selectedKey = key end
	frame:Show()
	Window.SelectTab(name or current or ns.DB.options.window.tab)
end

function ns.ShowPanel() ns.ShowTab() end

function ns.HideWindow()
	if frame then frame:Hide() end
end

function ns.TogglePanel()
	if frame and frame:IsShown() then frame:Hide() else ns.ShowPanel() end
end

function ns.ShowEditor(key) ns.ShowTab("customize", key) end
function ns.ShowGuide(key) ns.ShowTab("deck", key) end

function Window.ApplyScale()
	if frame then frame:SetScale(ns.DB.options.window.scale) end
end

ns.Listen(Window.Refresh)
ns.On("PLAYER_REGEN_DISABLED", Window.Refresh)
ns.On("PLAYER_REGEN_ENABLED", Window.Refresh)
