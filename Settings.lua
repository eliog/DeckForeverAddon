-- Settings: the user-facing model of the preset settings (pure data), used by the Customize
-- window and by overrides. Each entry is one control: a CVar and its selectable levels.
--
-- owner: a raw CVar the client derives from an index CVar. When the user overrides the index
-- CVar, the preset's raw value is dropped so the client derives it from the user's choice,
-- unless DERIVED gives the matching raw value (Secondary Lighting writes giQuality too).
local _, ns = ...

local META = ns.CVarMeta

local OWNERS = {
	giQuality = "graphicsLightMode",
	shadowMode = "graphicsShadowQuality",
	SSAO = "graphicsSSAO",
	particleDensity = "graphicsParticleDensity",
	waterDetail = "graphicsLiquidDetail",
	projectedTextures = "graphicsProjectedTextures",
}
for raw, owner in pairs(OWNERS) do
	META[raw].owner = owner
	local twin = META[raw].twin
	if twin then META[twin].owner = META[owner].twin end
end

-- Calibrated: graphicsLightMode 0/1/2 (Fair/Good/High) writes giQuality 1/2/3.
ns.DERIVED = {
	giQuality = function(lightMode) return lightMode + 1 end,
}

local function Levels(names, first)
	local t = {}
	for i, name in ipairs(names) do t[i] = { value = (first or 0) + i - 1, text = name } end
	return t
end

local function Numbers(values, fmt)
	local t = {}
	for i, v in ipairs(values) do t[i] = { value = v, text = fmt and fmt(v) or tostring(v) } end
	return t
end

local OFF_ON = Levels({ "Off", "On" })
local TEN = Levels({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" })
local function Percent(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end

ns.SETTING_GROUPS = {
	{
		label = "Lighting & Shadows",
		settings = {
			{ cvar = "graphicsLightMode", label = "Secondary Lighting", levels = Levels({ "Fair", "Good", "High" }),
				note = "Biggest performance lever in Forever" },
			{ cvar = "graphicsShadowQuality", label = "Shadow Quality",
				levels = Levels({ "Low", "Fair", "Good", "High", "Ultra", "Ultra High" }) },
			{ cvar = "graphicsSSAO", label = "Ambient Occlusion", levels = Levels({ "Off", "Low", "Good", "High", "Ultra" }) },
			{ cvar = "graphicsDepthEffects", label = "Depth Effects", levels = Levels({ "Off", "Low", "Good", "High" }) },
			{ cvar = "graphicsComputeEffects", label = "Compute Effects", levels = Levels({ "Off", "Low", "Good", "High", "Ultra" }) },
		},
	},
	{
		label = "Effects",
		settings = {
			{ cvar = "graphicsParticleDensity", label = "Particle Density",
				levels = Levels({ "Off", "Low", "Fair", "Good", "High", "Ultra" }) },
			{ cvar = "graphicsSpellDensity", label = "Spell Density", levels = Levels({ "Essential", "Some", "Everything" }) },
			{ cvar = "graphicsProjectedTextures", label = "Projected Textures", levels = Levels({ "Off", "On" }),
				note = "Shows ground spell effects" },
			{ cvar = "graphicsLiquidDetail", label = "Liquid Detail", levels = Levels({ "Low", "Fair", "Good", "High" }) },
			{ cvar = "sunShafts", label = "Sun Shafts", levels = Levels({ "Off", "Low", "High" }) },
			{ cvar = "refraction", label = "Refraction", levels = Levels({ "Off", "Low", "High" }) },
			{ cvar = "reflectionMode", label = "Reflections", levels = Levels({ "Off", "Low", "Good", "High" }) },
			{ cvar = "rippleDetail", label = "Ripple Detail", levels = Levels({ "Off", "Low", "High" }) },
			{ cvar = "volumeFogLevel", label = "Volumetric Fog", levels = Levels({ "Off", "Low", "Good", "High" }) },
		},
	},
	{
		label = "Detail & Distance",
		settings = {
			{ cvar = "graphicsViewDistance", label = "View Distance", levels = TEN },
			{ cvar = "graphicsEnvironmentDetail", label = "Environment Detail", levels = TEN },
			{ cvar = "graphicsGroundClutter", label = "Ground Clutter", levels = TEN },
			{ cvar = "graphicsTextureResolution", label = "Texture Resolution", levels = Levels({ "Low", "Fair", "High" }) },
		},
	},
	{
		label = "Frame Rate & Rendering",
		settings = {
			{ cvar = "maxFPS", label = "Max FPS", levels = Numbers({ 30, 36, 40, 45, 50, 60, 72, 90, 120 }) },
			{ cvar = "maxFPSBk", label = "Background FPS", levels = Numbers({ 10, 15, 20, 30, 40, 60 }) },
			{ cvar = "useTargetFPS", label = "Target Framerate", levels = OFF_ON,
				note = "Dynamic quality scaler; Off is faster" },
			{ cvar = "vsync", label = "VSync", levels = OFF_ON },
			{ cvar = "RenderScale", label = "Render Scale",
				levels = Numbers({ 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.99, 1.0 }, Percent),
				note = "99% enables FSR sharpening" },
			{ cvar = "ResampleQuality", label = "Upscaler", levels = Levels({ "Point", "Bilinear", "Bicubic", "FSR" }) },
			{ cvar = "ffxAntiAliasingMode", label = "Anti-Aliasing",
				levels = Levels({ "Off", "FXAA Low", "FXAA High", "CMAA", "CMAA2" }) },
			{ cvar = "physicsLevel", label = "Physics", levels = Levels({ "None", "Player Only", "Everyone" }),
				note = "Needs a game restart" },
		},
	},
	{
		label = "Interface",
		settings = {
			{ cvar = "cameraDistanceMaxZoomFactor", label = "Max Camera Distance",
				levels = Numbers({ 1.9, 2.2, 2.6 }, function(v) return ("x%.1f"):format(v) end) },
		},
	},
}

ns.SETTINGS = {}
for _, group in ipairs(ns.SETTING_GROUPS) do
	for _, s in ipairs(group.settings) do ns.SETTINGS[s.cvar] = s end
end

-- Text for a value: the level name when it matches one, else the raw value.
function ns.LevelText(cvar, value)
	local s = ns.SETTINGS[cvar]
	if value == nil then return "-" end
	if s then
		for _, l in ipairs(s.levels) do
			if ns.ValuesEqual(l.value, value) then return l.text end
		end
	end
	return ns.FormatValue(tonumber(value) or value)
end
