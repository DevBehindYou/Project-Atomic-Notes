# Atomic Notes — UI/UX Redesign

The app rebuilt on the **Technical Editorial** system from
`New-Design-Inspiration-Files/.../technical_editorial/DESIGN.md`.

**Nothing about behaviour changed.** Every route, screen, widget class,
constructor signature, callback and database call is identical to
`Old-Atomic-Notes-Revived`. This was a skin, not a rewrite — so none of the
revival bug fixes were disturbed.

## The system

| Token | Value | Role |
|---|---|---|
| Ink | `#15171B` | Type, borders, inverted blocks |
| Paper | `#F4F5F1` | The canvas |
| Signal | `#3A2FF0` | Reserved: sync, active states, focus, critical data |

- **Bebas Neue** — headings, uppercase, condensed
- **Hanken Grotesk** — body
- **JetBrains Mono** — metadata, counts, labels, "system status" voice

Radii are 4px (12px only for data chips). Borders are hairlines. **There are no
shadows** — depth comes from tonal layering, and the one "shadow" is a solid
2px zero-blur offset, mimicking offset print. 8px spacing base.

The app is now **light**. That's the faithful reading of the inspiration, which
is a Paper-ground design throughout.

## Where it lives

```
lib/theme/
├── app_tokens.dart   # colours, type scale, spacing, radii, strokes
├── app_theme.dart    # ThemeData — so unstyled Material widgets stay in-system
└── editorial.dart    # EditorialModule, MonoLabel, EditorialHeading, HairRule,
                      # SectionHeader, InkActionButton, GhostButton, DataChip,
                      # ArrowLink, InkLogoMark
```

No screen hardcodes a hex value or a font size — they compose from these.

## Notable translations

- **Note cards** follow the reference's case-study card: mono date on top, a
  rule, then the title in condensed display type, then the body. Flat, hairline
  border, white fill on the Paper grid.
- **Settings rows** became rule-separated lines (the FAQ-accordion pattern)
  rather than filled pills, with a Signal arrow as the only colour.
- **The Database screen** became bento stat modules — big Bebas numerals with
  mono captions — which is what that data always wanted to be.
- **Bottom nav**: the active tab is a solid Ink block.
- **Dialogs** and the **colophon** on Settings use the system's inversion
  mechanism (Ink ground, Paper type) for emphasis.
- **Snackbars** are an inverted Ink strip with a Signal edge marker.

## Assets kept as-is

`logo_x.png` (light-on-dark atom) and the six `intro*.png` illustrations are
dark artwork. Rather than redraw them, they're framed in Ink blocks — which is
exactly how the reference treats logos and imagery on a Paper ground.
`photo.png` is neutral and needed no treatment.

Fonts are **bundled** (`assets/fonts/`, ~450 KB) rather than fetched via
`google_fonts`: this is a local-first app that has to render correctly offline,
and bundling keeps rendering deterministic.

## API compatibility

Some widgets take colour parameters from the old palette
(`MyFloatingButton.colorValue`, `CloudButton.clr`). Those parameters are still
accepted so no call site had to change, but they are now read as *intent* —
the old red maps to the error token, everything else to Ink. That keeps the
palette inside the system regardless of what a caller passes.

## Not verified by a build

There is no Flutter SDK on this machine. All 47 Dart files were checked for
structural damage and for missing/unused imports, and `pubspec.yaml` was
validated (including that every declared font file exists), but this has not
been compiled. Push it and let the workflow in `.github/workflows/` tell you.

Two things worth looking at specifically on first run:

1. **Contrast.** A scripted pass converted the old dark palette; each result
   was reviewed, and four Ink-on-Ink collisions were found and fixed (lock
   screen, settings colophon, the profile save button, the reset button). If
   anything is invisible, that's the class of bug to suspect.
2. **Bebas Neue is uppercase-only by design** and has no bold weight. Headings
   pass through `.toUpperCase()` deliberately.
