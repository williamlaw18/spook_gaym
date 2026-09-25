# Visual Style

Status: draft

## Summary

Art direction targets a PS1/PS2-era 3D look: low-poly models, low-resolution
and affine-warped textures, limited/blocky lighting, low internal render
resolution. The overall feel should be dark and a little "crispy" — visible
grain, dither, and light artifacting rather than a clean modern
post-process look. The dated, slightly degraded rendering is meant to
support the horror tone directly (nostalgia-adjacent unease, obscured
detail, things half-glimpsed).

## Design notes

- Prioritize legibility of threats even within a deliberately low-fidelity
  look — horror from suggestion/dread, not from illegible noise.
- Lighting should lean dark by default; the surface homebase can be
  comparatively lit/safe-feeling while the caverns lean darker, reinforcing
  the surface/depths split in `dungeon-exploration.md`.
- As corruption escalates (`demon-and-corruption.md`), consider whether the
  visual treatment itself should shift (more grain/artifacting, color
  drift) so the world's degradation is felt visually, not just narratively.
- Godot implementation approach (low internal resolution + upscale,
  dithering shader, texture filtering settings, etc.) is a technical
  decision to make once the engine setup is underway — not decided yet.

## Open questions

- Target render resolution / pixel density.
- Color palette rules (e.g., limited palette vs. full range with grading).
- Whether PS1-style vertex "wobble"/affine texture warping is used, or just
  the low-poly/low-res look without the wobble.
- Concrete plan for the grain/crispy post-process (shader-based, baked into
  textures, or both).
