-- Apply: turn a preset into an ordered write plan, preview it, apply it.
local _, ns = ...

local META = ns.CVarMeta

function ns.GetPreset(key)
	return key and ns.Presets[key:lower()]
end

-- Overrides ----------------------------------------------------------------------
-- The user's changes to a preset, kept apart from the built-in values: DB.overrides[key][cvar].

function ns.GetOverrides(key)
	local all = ns.DB.overrides
	return all and all[key] or {}
end

function ns.HasOverrides(key)
	return next(ns.GetOverrides(key)) ~= nil
end

-- World value the preset writes for a CVar, with overrides; nil if the preset leaves it alone.
function ns.EffectiveValue(key, cvar)
	local ov = ns.GetOverrides(key)[cvar]
	if ov ~= nil then return ov end
	local preset = ns.GetPreset(key)
	return preset and preset.values[cvar]
end

-- Sets an override, or removes it when value is nil or equals the built-in value.
-- Returns false (and changes nothing) if the CVar is not a preset setting or out of range.
function ns.SetOverride(key, cvar, value)
	local preset = ns.GetPreset(key)
	if not preset or not META[cvar] or META[cvar].twinOf then return false, "not a preset setting" end
	key = key:lower()
	if value ~= nil then
		value = tonumber(value) or value
		local good, why = ns.InRange(cvar, value)
		if not good then return false, why end
	end
	ns.DB.overrides = ns.DB.overrides or {}
	local ov = ns.DB.overrides[key] or {}
	if value == nil or ns.ValuesEqual(preset.values[cvar], value) then
		ov[cvar] = nil
	else
		ov[cvar] = value
	end
	ns.DB.overrides[key] = next(ov) and ov or nil
	ns.Changed()
	return true
end

function ns.ResetOverrides(key)
	if ns.DB.overrides then ns.DB.overrides[key:lower()] = nil end
	ns.Changed()
end

-- Plan --------------------------------------------------------------------------------

-- World and raid values for a preset after overrides. An overridden CVar sets its raid twin to
-- the same value, and drops the raw CVars it owns (the client derives them) unless DERIVED
-- gives their value.
local function EffectiveValues(preset, ov)
	local values, raid = {}, {}
	for name, v in pairs(preset.values) do values[name] = v end
	for name, v in pairs(preset.raid) do raid[name] = v end
	for name, v in pairs(ov) do
		values[name] = v
		raid[name] = nil
	end
	for raw, m in pairs(META) do
		if m.owner and not m.twinOf and ov[raw] == nil and ov[m.owner] ~= nil then
			local derive = ns.DERIVED[raw]
			values[raw] = derive and derive(ov[m.owner]) or nil
			raid[raw] = nil
		end
	end
	return values, raid
end

-- Ordered list of { name, value } for a preset, honouring overrides and the raid-twin option.
function ns.BuildPlan(key)
	local preset = ns.GetPreset(key)
	if not preset then return nil end
	local opts = ns.DB.options
	local world, raid = EffectiveValues(preset, ns.GetOverrides(key:lower()))
	local values = {}
	for name, v in pairs(world) do
		values[name] = v
		local twin = META[name] and META[name].twin
		if twin and opts.syncRaid then
			local rv = raid[name]
			if rv == nil then rv = v end
			values[twin] = rv
		end
	end

	local names = {}
	for name in pairs(values) do names[#names + 1] = name end
	ns.SortByTier(names)
	local plan = {}
	for _, name in ipairs(names) do
		plan[#plan + 1] = { name = name, value = values[name] }
	end
	return plan
end

-- What applying the preset would change: { name, current, target, status } where status is
-- "change", "same" or "unknown". Changes come first.
function ns.PreviewPreset(key)
	local plan = ns.BuildPlan(key)
	if not plan then return nil end
	local rows = {}
	for _, e in ipairs(plan) do
		local st = ns.GetCVarState(e.name)
		local status
		if not st then
			status = "unknown"
		elseif ns.ValuesEqual(st.value, e.value) then
			status = "same"
		else
			status = "change"
		end
		rows[#rows + 1] = { name = e.name, current = st and st.value, target = ns.FormatValue(e.value), status = status }
	end
	local rank = { change = 1, same = 2, unknown = 3 }
	local indexed = {}
	for i, r in ipairs(rows) do indexed[i] = { r = r, i = i } end
	table.sort(indexed, function(a, b)
		if rank[a.r.status] ~= rank[b.r.status] then return rank[a.r.status] < rank[b.r.status] end
		return a.i < b.i
	end)
	for i, x in ipairs(indexed) do rows[i] = x.r end
	return rows
end

-- Number of known CVars in the preset that no longer hold the preset value.
function ns.PresetDrift(key)
	local n = 0
	for _, row in ipairs(ns.PreviewPreset(key) or {}) do
		if row.status == "change" then n = n + 1 end
	end
	return n
end

-- One line per changed CVar that needs a reload or restart to take full effect.
function ns.PrintHints(changed)
	local shown = {}
	for _, name in ipairs(changed) do
		local hint = META[name] and META[name].hint
		if hint and not shown[hint] then
			shown[hint] = true
			ns.Print("  |cffffff60Note:|r %s.", hint)
		end
	end
end

function ns.ApplyPreset(key)
	local preset = ns.GetPreset(key)
	if not preset then
		ns.Print("Unknown preset %q. Use performance, battery or quality.", tostring(key))
		return false
	end
	key = key:lower()
	return ns.RunWhenSafe("settings", function()
		local plan = ns.BuildPlan(key)
		local undo = { cvars = ns.CaptureAll(), activePreset = ns.DB.activePreset }
		local tookSnapshot = ns.TakeSnapshot()
		undo.tookSnapshot = tookSnapshot
		local res = ns.WriteCVars(plan)
		ns.DB.activePreset = key
		ns.DB.lastApply = { preset = key, time = time(), skipped = res.skipped, failed = res.failed }
		ns.ReportResult("Applied " .. preset.label, res)
		if tookSnapshot then
			ns.Print("Your previous settings were saved. Use Restore previous to go back.")
		end
		ns.PrintHints(res.changed)
		local deck = ns.DeckSummary(key)
		if deck then ns.Print("  Steam Deck (... > Performance): %s.", deck) end
		ns.Changed()
		if #res.changed > 0 then ns.OfferKeep(preset.label, undo) end
	end)
end
