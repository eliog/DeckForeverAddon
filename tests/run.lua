-- Tiny test runner. Usage: luajit tests/run.lua  (LuaJIT = Lua 5.1, same as the client)
local ROOT = (debug.getinfo(1, "S").source:match("^@(.*)tests/run%.lua$")) or "./"
package.path = ROOT .. "tests/?.lua;" .. ROOT .. "?.lua;" .. package.path

local tests = {}

function test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end

function eq(actual, expected, msg)
	if actual ~= expected then
		error(("%sexpected %s, got %s"):format(msg and (msg .. ": ") or "", tostring(expected), tostring(actual)), 2)
	end
end

function ok(cond, msg)
	if not cond then error(msg or "assertion failed", 2) end
end

function contains(haystack, needle, msg)
	if not haystack:find(needle, 1, true) then
		error(("%sexpected to find %q in:\n%s"):format(msg and (msg .. ": ") or "", needle, haystack), 2)
	end
end

local files = { "test_cvars", "test_apply", "test_snapshot", "test_ui_slash", "test_keep_minimap", "test_editor" }
-- extra suites from the command line: luajit tests/run.lua dir/test_x ...
for i = 1, #arg do files[#files + 1] = arg[i] end
for _, f in ipairs(files) do require(f) end

local passed, failed = 0, 0
for _, t in ipairs(tests) do
	local good, err = xpcall(t.fn, debug.traceback)
	if good then
		passed = passed + 1
	else
		failed = failed + 1
		print(("FAIL %s\n%s\n"):format(t.name, err))
	end
end
print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
