-- Presets: CVar metadata and preset values (pure data).
--
-- Tiers set the write order. Writing a "graphics*" index CVar makes the client rewrite the raw
-- CVars behind it, so index CVars go first and raw overrides after:
--   master (graphicsQuality) -> index (graphics*) -> raw -> other (fps, render) -> ui
--
-- seen   = name present in the Forever client's own Config.wtf (copy in tests/fixtures/)
-- verify = the value meaning is not confirmed for Forever; /deckforever check flags it
-- min/max = sanity bounds for preset values (ranges from the retail client unless noted)
local _, ns = ...

local TIER_RANK = { master = 1, index = 2, raw = 3, other = 4, ui = 5 }
ns.TIER_RANK = TIER_RANK

local META, ORDER = {}, {}
ns.CVarMeta = META

local function def(name, tier, twin, t)
	t = t or {}
	t.name, t.tier, t.twin = name, tier, twin
	t.order = #ORDER + 1
	META[name] = t
	ORDER[#ORDER + 1] = name
	if twin then
		-- the twin shares the metadata but is never a twin itself
		local tw = {}
		for k, v in pairs(t) do tw[k] = v end
		tw.name, tw.twin, tw.twinOf = twin, nil, name
		META[twin] = tw
	end
end

-- master
def("graphicsQuality", "master", "RAIDgraphicsQuality", { seen = true, min = 0, max = 9 })

-- index CVars (the Options panel sliders)
def("graphicsShadowQuality", "index", "raidGraphicsShadowQuality", { seen = true, min = 0, max = 5 })
def("graphicsLiquidDetail", "index", "raidGraphicsLiquidDetail", { seen = true, min = 0, max = 3 })
def("graphicsParticleDensity", "index", "raidGraphicsParticleDensity", { seen = true, min = 0, max = 5 })
def("graphicsSSAO", "index", "raidGraphicsSSAO", { seen = true, min = 0, max = 4 })
def("graphicsDepthEffects", "index", "raidGraphicsDepthEffects", { seen = true, min = 0, max = 3 })
def("graphicsComputeEffects", "index", "raidGraphicsComputeEffects", { seen = true, min = 0, max = 4,
	hint = "Compute Effects frees its frame time fully only after /reload" })
def("graphicsOutlineMode", "index", "raidGraphicsOutlineMode", { seen = true, min = 0, max = 2 })
def("graphicsTextureResolution", "index", "raidGraphicsTextureResolution", { seen = true, min = 0, max = 2 })
def("graphicsSpellDensity", "index", "raidGraphicsSpellDensity", { seen = true, min = 0, max = 2 }) -- 0 Essential, 1 Some, 2 Everything
def("graphicsProjectedTextures", "index", "raidGraphicsProjectedTextures", { seen = true, min = 0, max = 1 })
def("graphicsViewDistance", "index", "raidGraphicsViewDistance", { seen = true, min = 0, max = 9 })
def("graphicsEnvironmentDetail", "index", "raidGraphicsEnvironmentDetail", { seen = true, min = 0, max = 9 })
def("graphicsGroundClutter", "index", "raidGraphicsGroundClutter", { seen = true, min = 0, max = 9 })
-- Secondary Lighting, calibrated on build 70338: 0 Fair, 1 Good, 2 High (writes giQuality 1/2/3)
def("graphicsLightMode", "index", "raidGraphicsLightMode", { seen = true, min = 0, max = 2 })
def("graphicsPBRLiquidDetail", "index", "raidGraphicsPBRLiquidDetail", { seen = true })
def("graphicsBloomUserMult", "index", "raidGraphicsBloomUserMult", { seen = true })

-- raw CVars (twins use the casing from Config.wtf; CVar names are case-insensitive)
-- 1 Fair, 2 Good, 3 High (calibrated). 0 is accepted but not offered by Options.
def("giQuality", "raw", "RAIDgiQuality", { seen = true, min = 1, max = 3 })
def("shadowMode", "raw", "RAIDshadowMode", { seen = true, min = 0, max = 3 })
def("SSAO", "raw", "RAIDSSAO", { seen = true, min = 0, max = 4 })
def("particleDensity", "raw", "RAIDparticleDensity", { seen = true, min = 10, max = 100 })
def("waterDetail", "raw", "RAIDWaterDetail", { seen = true, min = 0, max = 3 })
def("projectedTextures", "raw", "RAIDprojectedTextures", { seen = true, min = 0, max = 1 })
def("sunShafts", "raw", "RAIDsunShafts", { seen = true, min = 0, max = 2 })
def("refraction", "raw", "RAIDrefraction", { seen = true, min = 0, max = 2 })
def("reflectionMode", "raw", "RAIDreflectionMode", { seen = true, min = 0, max = 3 })
def("rippleDetail", "raw", "RAIDrippleDetail", { seen = true, min = 0, max = 2 })
def("volumeFogLevel", "raw", "RAIDVolumeFogLevel", { seen = true, min = 0, max = 3 })
def("weatherDensity", "raw", "RAIDweatherDensity", { seen = true, min = 0, max = 3 })
-- raw CVars the index CVars rewrite; not in any preset, snapshotted so Restore is exact
def("farclip", "raw", "RAIDfarclip", { seen = true })
def("horizonStart", "raw", "RAIDhorizonStart", { seen = true })
def("horizonClip", "raw", "RAIDhorizonClip", { seen = true })
def("groundEffectDensity", "raw", "RAIDgroundEffectDensity", { seen = true })
def("groundEffectDist", "raw", "RAIDgroundEffectDist", { seen = true })
def("lodObjectCullSize", "raw", "RAIDlodObjectCullSize", { seen = true })
def("lodObjectFadeScale", "raw", "RAIDlodObjectFadeScale", { seen = true })
def("lodObjectMinSize", "raw", "RAIDlodObjectMinSize", { seen = true })
def("wmoLodDist", "raw", "RAIDwmoLodDist", { seen = true })
def("entityLodDist", "raw", "RAIDentityLodDist", { seen = true })
def("entityShadowFadeScale", "raw", "RAIDentityShadowFadeScale", { seen = true })
def("TerrainLodDiv", "raw", "RAIDTerrainLodDiv", { seen = true })
def("shadowNumCascades", "raw", "RAIDshadowNumCascades", { seen = true })
def("shadowBlendCascades", "raw", "RAIDshadowBlendCascades", { seen = true })
def("particleMTDensity", "raw", "RAIDparticleMTDensity", { seen = true })
def("pbrLiquidDetail", "raw", "RAIDpbrLiquidDetail", { seen = true })
def("OutlineEngineMode", "raw", "RAIDOutlineEngineMode", { seen = true })
def("spellClutter", "raw", nil, { seen = true })

-- frame rate and rendering (names from warcraft.wiki.gg, not yet seen in Forever)
def("vsync", "other", nil, { seen = true, min = 0, max = 1 })
def("useTargetFPS", "other", nil, { min = 0, max = 1 })
def("useMaxFPS", "other", nil, { min = 0, max = 1 })
def("maxFPS", "other", nil, { min = 8, max = 200 })
def("useMaxFPSBk", "other", nil, { min = 0, max = 1 })
def("maxFPSBk", "other", nil, { min = 8, max = 200 })
def("maxFPSLoading", "other", nil, { min = 8, max = 200 })
def("RenderScale", "other", nil, { min = 0.33, max = 1.0 })
def("ResampleQuality", "other", nil, { min = 0, max = 3 }) -- 0 Point, 1 Bilinear, 2 Bicubic, 3 FSR (Advanced)
def("ffxAntiAliasingMode", "other", nil, { min = 0, max = 4 }) -- 0 off, 1 FXAA Low, 2 FXAA High, 3 CMAA, 4 CMAA2
def("MSAAQuality", "other", nil, { min = 0, max = 4 }) -- reads back as "samples,coverage"
def("physicsLevel", "other", nil, { min = 0, max = 2, hint = "Physics takes effect after a game restart" })

-- interface
-- (uiScale/useUiScale are locked for addons in Forever: UI scale stays a game Option)
def("cameraDistanceMaxZoomFactor", "ui", nil, { min = 1.0, max = 2.6 })
-- Reported by /deckforever check, never written. The Gamepad UI checkbox writes
-- InputDeviceInterfaceStyle (plus soft-target and camera-follow CVars) and reloads the UI, so
-- it stays a one-click Options choice. GamePadEnable already defaults to 1 in Forever.
ns.REPORT_ONLY = {
	{ name = "InputDeviceInterfaceStyle", note = "1 = Gamepad UI on (set in Options)" },
	{ name = "GamePadEnable", note = "controller input" },
	{ name = "GxApi", note = "restart-only" },
	{ name = "GxMaximize", note = "restart-only" },
	{ name = "gxWindow", note = "restart-only" },
}

-- Presets ----------------------------------------------------------------------
-- values: normal CVars. raid: raid-twin values that differ from the normal value.

local COMMON = {
	useTargetFPS = 0, useMaxFPS = 1, useMaxFPSBk = 1, maxFPSLoading = 30, vsync = 1,
	ResampleQuality = 3, graphicsProjectedTextures = 1, projectedTextures = 1,
	graphicsTextureResolution = 2, graphicsSpellDensity = 0, MSAAQuality = 0, physicsLevel = 1,
	cameraDistanceMaxZoomFactor = 2.6,
}

local function preset(t)
	for k, v in pairs(COMMON) do
		if t.values[k] == nil then t.values[k] = v end
	end
	t.raid = t.raid or {}
	return t
end

ns.Presets = {
	order = { "battery", "balanced", "performance", "quality" },

	battery = preset({
		label = "Battery", desc = "30 fps, longest play time",
		values = {
			graphicsLightMode = 0, giQuality = 1, maxFPS = 30, maxFPSBk = 20, RenderScale = 0.85,
			graphicsShadowQuality = 0, shadowMode = 0, graphicsSSAO = 1, SSAO = 1,
			graphicsDepthEffects = 0, graphicsComputeEffects = 1,
			graphicsParticleDensity = 2, particleDensity = 40,
			graphicsLiquidDetail = 1, waterDetail = 1,
			graphicsViewDistance = 3, graphicsEnvironmentDetail = 4, graphicsGroundClutter = 3,
			ffxAntiAliasingMode = 2,
			sunShafts = 0, refraction = 0, reflectionMode = 0, rippleDetail = 1, volumeFogLevel = 0,
			weatherDensity = 1,
		},
		raid = { graphicsViewDistance = 3, graphicsGroundClutter = 1, graphicsSSAO = 0 },
	}),

	-- Battery plus real shadows (level 2 is where the engine's shaded lighting path starts;
	-- level 1 costs the same and changes nothing). Measured +1 W.
	balanced = preset({
		label = "Balanced", desc = "45 fps, shadows and shading",
		values = {
			graphicsLightMode = 0, giQuality = 1, maxFPS = 45, maxFPSBk = 20, RenderScale = 0.85,
			graphicsShadowQuality = 2, shadowMode = 2, graphicsSSAO = 1, SSAO = 1,
			graphicsDepthEffects = 0, graphicsComputeEffects = 1,
			graphicsParticleDensity = 2, particleDensity = 40,
			graphicsLiquidDetail = 1, waterDetail = 1,
			graphicsViewDistance = 3, graphicsEnvironmentDetail = 4, graphicsGroundClutter = 3,
			ffxAntiAliasingMode = 2,
			sunShafts = 0, refraction = 0, reflectionMode = 0, rippleDetail = 1, volumeFogLevel = 0,
			weatherDensity = 1,
		},
		raid = { graphicsViewDistance = 3, graphicsGroundClutter = 1, graphicsSSAO = 0, graphicsShadowQuality = 0 },
	}),

	performance = preset({
		label = "Max FPS", desc = "60 fps, full power (cities ~50)",
		values = {
			graphicsLightMode = 0, giQuality = 1, maxFPS = 60, maxFPSBk = 30, RenderScale = 1.0,
			graphicsShadowQuality = 2, shadowMode = 2, graphicsSSAO = 1, SSAO = 1,
			graphicsDepthEffects = 0, graphicsComputeEffects = 1,
			graphicsParticleDensity = 3, particleDensity = 60,
			graphicsLiquidDetail = 1, waterDetail = 1,
			graphicsViewDistance = 5, graphicsEnvironmentDetail = 4, graphicsGroundClutter = 5,
			ffxAntiAliasingMode = 4,
			sunShafts = 0, refraction = 1, reflectionMode = 0, rippleDetail = 1, volumeFogLevel = 0,
			weatherDensity = 2,
		},
		raid = { graphicsViewDistance = 4, graphicsGroundClutter = 3, graphicsParticleDensity = 2 },
	}),

	-- Everything high at a 30 fps cap. Reflections, fog and SSAO stay one step short of max:
	-- everything at max measured 2.5 fps on a Deck (reflections re-render the scene).
	quality = preset({
		label = "Max Quality", desc = "30 fps, best visuals; plugged in, not for cities",
		values = {
			graphicsLightMode = 2, giQuality = 3, maxFPS = 30, maxFPSBk = 30, RenderScale = 1.0,
			graphicsShadowQuality = 4, shadowMode = 3, graphicsSSAO = 3, SSAO = 3,
			graphicsDepthEffects = 2, graphicsComputeEffects = 4,
			graphicsParticleDensity = 5, particleDensity = 100,
			graphicsLiquidDetail = 3, waterDetail = 3,
			graphicsViewDistance = 8, graphicsEnvironmentDetail = 8, graphicsGroundClutter = 8,
			ffxAntiAliasingMode = 4,
			sunShafts = 2, refraction = 2, reflectionMode = 2, rippleDetail = 2, volumeFogLevel = 2,
			weatherDensity = 3, graphicsSpellDensity = 2,
		},
		raid = { graphicsViewDistance = 6, graphicsEnvironmentDetail = 6, graphicsGroundClutter = 5,
			graphicsShadowQuality = 3, graphicsParticleDensity = 4, reflectionMode = 1 },
	}),
}

-- Sorts CVar names into write order: by tier, then declaration order, each twin right
-- after its normal CVar. Unknown names go last.
function ns.SortByTier(names)
	table.sort(names, function(a, b)
		local ma, mb = META[a], META[b]
		local ra = ma and TIER_RANK[ma.tier] or 99
		local rb = mb and TIER_RANK[mb.tier] or 99
		if ra ~= rb then return ra < rb end
		local oa = ma and ma.order or 999
		local ob = mb and mb.order or 999
		if oa ~= ob then return oa < ob end
		-- normal before twin
		local ta = (ma and ma.twinOf) and 1 or 0
		local tb = (mb and mb.twinOf) and 1 or 0
		if ta ~= tb then return ta < tb end
		return a < b
	end)
	return names
end

-- Every CVar the addon knows (normal + twins), in write order.
function ns.AllKnownCVars()
	local names = {}
	for name in pairs(META) do names[#names + 1] = name end
	return ns.SortByTier(names)
end
