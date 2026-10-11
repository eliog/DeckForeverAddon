-- Snapshot: the user's own settings, taken before the first preset is applied.
--
-- Taken only when no snapshot exists, so Performance -> Battery -> Restore returns to the
-- settings the user had before DeckForever, not to Performance. Covers every CVar the addon
-- knows (including raw CVars the index CVars rewrite) so Restore is exact.
local _, ns = ...

function ns.HasSnapshot()
	return ns.DB.snapshot ~= nil
end

-- Current value of every CVar the addon knows and the client has: { name = value }.
function ns.CaptureAll()
	local cvars = {}
	for _, name in ipairs(ns.AllKnownCVars()) do
		local st = ns.GetCVarState(name)
		if st and st.value ~= nil then cvars[name] = st.value end
	end
	return cvars
end

-- { name = value } -> entries for WriteCVars, in write order.
function ns.EntriesFrom(cvars)
	local names = {}
	for name in pairs(cvars) do names[#names + 1] = name end
	ns.SortByTier(names)
	local entries = {}
	for _, name in ipairs(names) do
		entries[#entries + 1] = { name = name, value = cvars[name] }
	end
	return entries
end

-- Returns true if a snapshot was taken now.
function ns.TakeSnapshot()
	if ns.DB.snapshot then return false end
	local _, build = GetBuildInfo()
	ns.DB.snapshot = { taken = time(), build = build, cvars = ns.CaptureAll() }
	return true
end

-- Entries for WriteCVars, in write order.
function ns.SnapshotEntries()
	local snap = ns.DB.snapshot
	return snap and ns.EntriesFrom(snap.cvars) or {}
end

-- CVars whose current value differs from the snapshot.
function ns.SnapshotDrift()
	local drift = {}
	for _, e in ipairs(ns.SnapshotEntries()) do
		local cur = C_CVar.GetCVar(e.name)
		if not ns.ValuesEqual(cur, e.value) then
			drift[#drift + 1] = { name = e.name, want = e.value, got = cur }
		end
	end
	return drift
end

-- Puts the snapshot back. The snapshot is kept if anything failed, so Restore can be retried.
function ns.RestoreSnapshot()
	if not ns.DB.snapshot then
		ns.Print("Nothing to restore: no preset has been applied.")
		return false
	end
	return ns.RunWhenSafe("settings", function()
		ns.CancelKeep()
		local res = ns.WriteCVars(ns.SnapshotEntries(), { noRangeCheck = true })
		ns.ReportResult("Restored previous settings", res)
		local drift = ns.SnapshotDrift()
		if #res.failed == 0 and #drift == 0 then
			ns.DB.snapshot = nil
		else
			ns.Print("%d settings differ from the snapshot; it is kept so you can retry.", #drift)
		end
		ns.DB.activePreset = nil
		ns.Changed()
	end)
end
