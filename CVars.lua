-- CVars: defensive reads/writes. Never assumes a CVar exists.
local _, ns = ...

local META = ns.CVarMeta

-- Returns a table describing the CVar in the running client, or nil if the client does not
-- know it. Fields: value, default, locked, readOnly.
function ns.GetCVarState(name)
	if C_CVar.GetCVarInfo then
		local value, default, _, _, locked, secure, readOnly = C_CVar.GetCVarInfo(name)
		if value == nil and default == nil then return nil end
		-- secure CVars cannot be written by addons (SetCVar throws), so treat them as locked
		return { value = value, default = default, locked = (locked or secure) and true or false,
			readOnly = readOnly and true or false }
	end
	local default = C_CVar.GetCVarDefault(name)
	if default == nil then return nil end
	return { value = C_CVar.GetCVar(name), default = default, locked = false, readOnly = false }
end

function ns.CVarExists(name)
	return ns.GetCVarState(name) ~= nil
end

-- Numbers as the client writes them: integers without decimals, floats trimmed.
function ns.FormatValue(v)
	if type(v) == "number" then
		if v == math.floor(v) then return string.format("%d", v) end
		return (string.format("%.4f", v):gsub("0+$", ""))
	end
	return tostring(v)
end

-- "1", "1.000000" and 1 are the same value. Some CVars read back with extra fields
-- (MSAAQuality: "samples,coverage"): only the first field is compared then.
local function FirstField(v)
	return (tostring(v):match("^([^,]*),")) or v
end

function ns.ValuesEqual(a, b)
	if a == nil or b == nil then return a == b end
	a, b = FirstField(a), FirstField(b)
	local na, nb = tonumber(a), tonumber(b)
	if na and nb then return math.abs(na - nb) < 1e-4 end
	return tostring(a):lower() == tostring(b):lower()
end

-- Checks a preset value against the bounds in META. Returns ok, reason.
function ns.InRange(name, value)
	local m = META[name]
	local n = tonumber(value)
	if not m or not n then return true end
	if m.min and n < m.min then return false, ("below min %s"):format(ns.FormatValue(m.min)) end
	if m.max and n > m.max then return false, ("above max %s"):format(ns.FormatValue(m.max)) end
	return true
end

-- Writes entries ({ name = , value = }) in the given order. Each value is compared against a
-- live read at write time, so raw CVars see what the index CVars before them changed.
-- opts.noRangeCheck skips InRange (used by Restore: the user's own values are always valid).
-- Returns { changed = {names}, unchanged = {names}, skipped = {{name, reason}}, failed = {{name, want, got}} }
function ns.WriteCVars(entries, opts)
	opts = opts or {}
	local res = { changed = {}, unchanged = {}, skipped = {}, failed = {} }
	for _, e in ipairs(entries) do
		local st = ns.GetCVarState(e.name)
		local ok, why = true, nil
		if not st then
			ok, why = false, "unknown to this client"
		elseif st.readOnly or st.locked then
			ok, why = false, "locked"
		elseif not opts.noRangeCheck then
			ok, why = ns.InRange(e.name, e.value)
		end

		if not ok then
			table.insert(res.skipped, { name = e.name, reason = why })
		elseif ns.ValuesEqual(st.value, e.value) then
			table.insert(res.unchanged, e.name)
		else
			-- SetCVar throws (instead of returning false) for CVars addons may not write
			pcall(C_CVar.SetCVar, e.name, ns.FormatValue(e.value))
			local got = C_CVar.GetCVar(e.name)
			if ns.ValuesEqual(got, e.value) then
				table.insert(res.changed, e.name)
			else
				table.insert(res.failed, { name = e.name, want = ns.FormatValue(e.value), got = got })
			end
		end
	end
	return res
end

-- One line summary plus details of anything skipped or failed.
function ns.ReportResult(title, res)
	ns.Print("%s: %d changed, %d already set, %d skipped, %d failed.",
		title, #res.changed, #res.unchanged, #res.skipped, #res.failed)
	if #res.skipped > 0 then
		local byReason = {}
		local reasons = {}
		for _, s in ipairs(res.skipped) do
			if not byReason[s.reason] then
				byReason[s.reason] = {}
				table.insert(reasons, s.reason)
			end
			table.insert(byReason[s.reason], s.name)
		end
		for _, reason in ipairs(reasons) do
			ns.Print("  skipped (%s): %s", reason, table.concat(byReason[reason], ", "))
		end
	end
	for _, f in ipairs(res.failed) do
		ns.Print("  |cffff6060%s|r: wanted %s, client kept %s", f.name, f.want, tostring(f.got))
	end
end
