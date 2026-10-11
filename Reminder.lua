-- Reminder: optional nudge to relog when the frame rate sags over a long session
-- (the Forever beta client leaks memory). Off by default.
local _, ns = ...

local SAMPLE_SECONDS = 60
local BASELINE_FROM, BASELINE_TO = 2, 6 -- minutes after login used for the baseline
local RECENT = 3                        -- samples averaged for the current frame rate

local ticker
local samples, baseline, reminded

local function Average(from, to)
	local sum, n = 0, 0
	for i = from, to do
		if samples[i] then sum, n = sum + samples[i], n + 1 end
	end
	return n > 0 and sum / n or nil
end

local function Tick()
	samples[#samples + 1] = GetFramerate()
	local minutes = #samples
	if not baseline and minutes >= BASELINE_TO then
		baseline = Average(BASELINE_FROM, BASELINE_TO)
	end
	local opts = ns.DB.options
	if reminded or not baseline or minutes < opts.reminderMinutes then return end
	local recent = Average(minutes - RECENT + 1, minutes)
	if recent and recent < baseline * (1 - opts.reminderSagPct / 100) then
		reminded = true
		ns.Print("Frame rate is down from %.0f to %.0f fps after %d minutes. A relog usually recovers it.",
			baseline, recent, minutes)
	end
end

function ns.StartReminder()
	if ticker or not ns.DB.options.reminder then return end
	samples, baseline, reminded = {}, nil, false
	ticker = C_Timer.NewTicker(SAMPLE_SECONDS, Tick)
end

function ns.StopReminder()
	if ticker then ticker:Cancel() end
	ticker = nil
end

ns.On("PLAYER_LOGIN", function() ns.StartReminder() end)
