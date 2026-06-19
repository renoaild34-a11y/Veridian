# Veridian — a realistic Iris shaderpack

Realistic deferred-forward shaderpack for **Minecraft 1.20.1 and 1.21.1**
(Fabric + Iris). One pack covers both versions — there is no version-specific
GLSL, so the same `shaders/` folder loads on either.

## Features

- **Soft shadow mapping** — distortion-focused shadow map, spiral PCF penumbra,
  colored shadows through stained glass / water.
- **Atmospheric scattering sky** — analytic Rayleigh + Mie single scattering,
  sun disc + halo, sunset warmth, night sky with twinkling stars.
- **Volumetric clouds** — raymarched fBm density, Beer–Lambert self-shadowing,
  dual-lobe Henyey–Greenstein scattering, powder term, temporal dither.
- **Water** — animated wave normals, Fresnel, sharp sun specular, refraction of
  the scene behind, and **screen-space reflections** (SSR) with binary refine.
- **SSAO** — view-space hemisphere ambient occlusion.
- **Volumetric light** — shadow-mapped sun shafts / god rays.
- **Atmospheric fog** that blends distant terrain into the sky.
- **Bloom** (separable Gaussian) + **ACES / Uchimura / Reinhard tonemap**,
  exposure, contrast, saturation, vibrance, white balance.
- **Distant Horizons support** — `dh_terrain`, optional `dh_water`, and
  `dh_shadow` programs; DH terrain is lit, shadowed, and fogged consistently
  with the near world. DH LOD water defaults off to avoid known transparency
  ordering artifacts over foreground foliage.

## Install

1. Minecraft 1.20.1 **or** 1.21.1 with **Fabric + Iris** (Sodium recommended).
   For distant terrain also install **Distant Horizons**.
2. Drop **`Veridian.zip`** into `.minecraft/shaderpacks/`.
3. **Options → Video → Shader Packs → Veridian → Apply**.
4. Tune everything under the in-game shader settings screens (Shadows,
   Lighting, Sky, Clouds, Water, Fog & God Rays, Reflections, AO, Post, DH).

## Pipeline order

```
shadow / dh_shadow        → shadow map (+ colored shadow buffer)
gbuffers_* / dh_*         → forward PBR-ish lighting  → colortex0
                            world normal + skylight    → colortex1
                            material (smooth/refl/id)  → colortex2
deferred                  → atmosphere + volumetric clouds over sky pixels
gbuffers_water            → waves, fresnel, SSR, refraction (after deferred)
composite                 → SSAO, volumetric light, atmospheric/DH fog
composite1 / composite2   → bloom bright-pass + separable blur (tex3 → tex4)
final                     → bloom combine, tonemap, grade, gamma
```

Shared code is in `shaders/lib/` (`settings`, `util`, `space`, `sky`, `clouds`,
`shadows`, `lighting`, `water`, `ssr`, `tonemap`). Every option lives in
`lib/settings.glsl` and is mirrored in `shaders.properties` as a menu slider/toggle.

## Performance notes / trade-offs

- Heaviest knobs: `CLOUD_STEPS × CLOUD_LIGHT_STEPS`, `SSR_STEPS`, `VL_STEPS`,
  `SSAO_SAMPLES`, `SHADOW_FILTER_SAMPLES`. Lower these first on weaker GPUs.
- `shadowMapResolution` / `shadowDistance` are `const` in `lib/shadows.glsl`.

## Honest limitations

- **No labPBR resource-pack support** yet — smoothness/metalness are constant
  per material class (terrain matte, water glossy). Specular maps aren't parsed.
- Water is tagged through `shaders/block.properties` + `mc_Entity`, so
  translucent foliage and underwater plants are not treated as water.
- SSR only reflects on-screen geometry (screen-space limitation) and falls back
  to the sky elsewhere.
- The atmosphere is an analytic approximation, not a multi-scatter LUT.
- Not GPU-tested in a live Iris instance on this machine — written to the
  documented Iris/OptiFine + DH API and reviewed for GLSL 1.20 compatibility.
  Report any compile log and it's a quick fix.

Inspired by the look of modern packs (e.g. Complementary) but written from
scratch — no code copied.
