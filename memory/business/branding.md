# Heediq — Brand & Design System

Full verbatim brand reference. `DECISIONS.md` (D-008, D-009, D-026) points here rather than
duplicating this detail. Migrated from the original conversations (not reconstructed from a
memory summary) — exact values below are safe to reproduce as-is.

## Name & meaning
"heediq" (stylized lowercase in UI; "HeedIQ" split-case with an amber "IQ" is also valid in some
contexts, e.g. marketing headers) layers three meanings:
- **Heed** — to listen carefully, pay attention
- **HQ** — High Quality
- **IQ** — Intelligence

The four amber slabs in the logo do double duty as a literal visual reference to "HQ."

Domain: heediq.com.

## Brand story
Every great system starts with a conversation — a meeting where ideas are discussed, decisions
are made, and requirements take shape. But somewhere between that conversation and the final
product, something always gets lost. Notes are incomplete, context fades, and what was "agreed"
in the room rarely matches what gets built.

HeedIQ exists to close that gap.

We started with a simple belief: if a machine could truly *heed* — listen, understand, and
retain — every conversation, then the painful translation from "what we discussed" to "what we
documented" to "what we built" could finally disappear.

Today, HeedIQ listens to your meetings and turns them into clear, structured requirements —
accurate, organized, and ready to act on. No more scrambling to write minutes. No more
requirements that drift from intent.

Tomorrow, HeedIQ goes further. The same intelligence that captures your requirements will help
build the systems behind them — turning conversation directly into working software, with humans
guiding the vision and HeedIQ handling the heavy lifting in between.

**HeedIQ: Heed every word. Build what matters.**

Other tagline options considered (kept as alternates, not the primary line):
- "Listen smarter. Build faster."
- "From conversation to requirements — automatically."
- "Your meetings, understood."
- "Intelligence that listens."

MVP-scope framing line: "HeedIQ turns your meetings into clear, actionable requirements —
instantly."

Future expansion narrative (pitch decks, etc.):
1. **Heed** — capture and understand conversations
2. **Define** — extract structured requirements
3. **Build** — auto-generate/implement into systems

## Brand register
Premium, restrained — Linear / Vercel / Raycast aesthetic. Smart but approachable; not
corporate-enterprise, not playful-consumer.

## Logo — `icon-master.svg` (reproduce verbatim, do not redesign)
Four angled (−12°) rounded amber slabs forming an abstract h+q monogram: slabs 1–2 read as "h,"
slabs 3–4 read as "q." Slabs 1–3 share a bottom edge, slabs 2–4 share a top edge; slab 1 is the
ascender, slab 4 is the descender. Centering uses computed bounding-box math to account for the
rotation offset — don't recompute, reuse the values as-is.

```svg
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect width="120" height="120" rx="18" fill="#1A1816" />
  <g transform="translate(55.4,51.2) rotate(-12)">
    <rect x="-33" y="-35" width="14" height="66" rx="7" fill="#F0A93B" /> <!-- slab 1 (ascender) -->
    <rect x="-14" y="-21" width="14" height="52" rx="7" fill="#F0A93B" /> <!-- slab 2 -->
    <rect x="5"   y="-21" width="14" height="52" rx="7" fill="#F0A93B" /> <!-- slab 3 -->
    <rect x="24"  y="-21" width="14" height="77" rx="7" fill="#F0A93B" /> <!-- slab 4 (descender) -->
  </g>
</svg>
```
The icon tile sits on page background `#0E0D0C` when shown in context (e.g. browser chrome,
homescreen).

## Asset library generated (`heediq-brand-assets.zip`)
Icon sizes: 1024, 512, 256, 192, 180, 152, 144, 128, 120, 96, 72, 64, 48, 32, 16px. Plus:
favicon.ico, monochrome variants, horizontal and stacked wordmark lockups, social/OG image
(1200×630), email header (600×160), business card, splash screen, loading-state concept, pattern
background, homescreen mockup.

PWA-specific subset (generated from `icon-master.svg`): `icon-192.png`, `icon-512.png`
(purpose: any), `maskable-192.png`, `maskable-512.png` (purpose: maskable, 78% safe zone).
`manifest.webmanifest`: name "heediq", background_color `#0E0D0C`, theme_color `#1A1816`,
display: standalone.

## Color tokens
First-pass locked palette: background `#0E0D0C`, surface `#1A1816`, amber accent `#F0A93B`,
off-white `#F5F3EF`, stone `#8A8782` — built as swappable theme tokens (CSS variables, not
hardcoded) so the whole palette can be replaced without structural changes.

Full token scale (the version used for actual UI implementation):
| Token | Value | Use |
|---|---|---|
| surface-0 | `#0E0D0C` | page background |
| surface-1 | `#1A1816` | cards/panels |
| surface-2 | `#242019` | elevated/hover |
| border | `#2E2A23` | hairlines |
| text-primary | `#EDE8E0` | headlines/key labels (sparing use) |
| text-secondary | `#A39A8C` | body/captions |
| text-disabled | `#6B645A` | disabled state |
| accent | `#F0A93B` | primary amber |
| accent-hover | `#FFC062` | hover |
| accent-pressed | `#D4922A` | pressed |

⚠️ Implementation note: Tailwind className-based dark backgrounds failed to apply correctly for
color-critical components in practice — use inline hex styles wherever exact color fidelity
matters.

## Typography
- UI: Inter or Geist, weights 400 and 500 only.
- Transcripts/timestamps/technical references: JetBrains Mono.
- Type scale:
  - Display/H1 — 28px / weight 600 / -0.02em tracking
  - H2 — 20px / weight 600
  - Body — 15px / weight 400 / line-height 1.5
  - Caption/label — 13px / weight 500 / text-secondary color
  - Mono (transcripts) — 14px / weight 400 / line-height 1.6

## Spacing & radius
- Spacing scale (4px base): 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px
- Radius: `sm` 8px (small controls), `md` 14px (cards/buttons), `lg` 24px (panels/sheets), `full`
  (pills, the Listen button)
- Border width: 1px hairline default, 2px for focus rings

## Listen button — three states
- **Idle:** solid accent fill, mic icon, label "Listen"
- **Recording:** surface-1 fill + accent border + pulsing accent ring, stop/square icon, label
  "Listening…", live waveform/timer shown below
- **Processing:** spinner/accent dots, label "Processing…", disabled appearance, text-disabled
  ring

## Empty states
- Home screen: no separate empty screen — inline hint above the Listen button: *"Your first
  transcript will appear here after recording."*
- Recordings library: dedicated empty state — *"No recordings yet — tap Listen to create your
  first one."*

## Wordmark usage
Both are valid, used by context:
- "heediq" — lowercase, stylized; primary in-product usage (app header, etc.)
- "HeedIQ" — split-case with amber "IQ"; some marketing/external contexts

## Working-pattern note
Memory-based regeneration of brand assets in a fresh chat (without the exact spec) produced
degraded results compared to the originally iterated output. Exact SVG coordinates and hex values
must always be preserved verbatim, never reconstructed from a paraphrased summary — this file is
the verbatim source going forward.
