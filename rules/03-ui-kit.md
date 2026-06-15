# UI Kit — Style Once, Reuse Everywhere

The goal: a single, comprehensive library of styled, reusable building blocks (buttons, inputs,
spinners, progress bars, cards, layouts, …) so any screen is assembled by **combining existing kit
components**, never by re-styling elements inline. One definition per element → consistent,
professional, fast to build. This pairs with `04-loading-and-feedback.md` (every wait visible) and
`07-engineering-standards.md` (a11y, perf).

Design register is already locked: restrained, premium, Linear / Vercel / Raycast alignment. Charcoal
+ amber tokens; Inter / Geist for UI; JetBrains Mono for transcripts. The kit *enforces* that register
so individual screens can't drift.

---

## 1. The golden rule
**No bespoke styling in feature code.** If a screen needs a visual element, it uses a kit component.
If the kit doesn't have it, you either (a) add a **variant** to an existing component, or (b) add a
**new component** to the kit — then use it. A raw `<button className="bg-amber-500 …">` in a feature
file is a bug. The only styling allowed in feature code is **layout composition** (arranging kit
components via the layout primitives), not visual styling of primitives.

## 2. Design tokens are the single source of truth
All visual values live in one place (Tailwind theme config + CSS variables), never hardcoded in
components:
- **Color** — charcoal/amber semantic tokens: `--bg`, `--surface`, `--border`, `--text`,
  `--text-muted`, `--accent` (amber), `--accent-fg`, plus state colors `--success`, `--warning`,
  `--danger`, `--info`. Components reference *semantic* tokens, never raw hex or raw palette steps.
- **Typography** — font families (Inter/Geist UI, JetBrains Mono transcripts), a type scale
  (display/title/body/caption/mono), weights, line-heights. No ad-hoc `text-[13px]`.
- **Spacing** — one spacing scale (4px base). No magic-number margins.
- **Radii, shadows, borders, z-index, motion** — each a named token set. Motion durations/easing are
  tokens too, so all transitions feel coherent.
Changing a token updates the whole app. If you're tempted to hardcode a value, add/extend a token
instead.

## 3. Layered structure (don't reach past a layer)
```
tokens (theme)         ← colors, type, spacing, motion — the only place raw values live
  └─ primitives        ← Button, Input, Select, Checkbox, Spinner, ProgressBar, Badge, Avatar, Toast…
       └─ composed      ← Card, Modal, Drawer, Table, Tabs, Toolbar, EmptyState, ErrorState, SkeletonBlock…
            └─ layouts   ← PageShell, AppSidebar, TopBar, SplitView, ContentContainer, Grid/Stack
                 └─ features ← screens compose the above; no raw styling here
```
Location: primitives + composed in `src/components/ui/`; layouts in `src/components/layout/`; feature
components in `src/features/<feature>/`. Features import down the stack, never the reverse.

## 4. Every interactive component declares all its states
A component is not done until it handles, visibly and consistently:
**default · hover · active/pressed · focus-visible · disabled · loading · error/invalid** (and
selected/checked where relevant). The three-state Listen button (idle / recording / processing) is the
canonical example — states are first-class, not afterthoughts. Loading and error states are mandatory,
not optional (see `04-loading-and-feedback.md`).

## 5. Variants over forks; composition over config
- Use a **variant system** (e.g. `class-variance-authority`) so a component exposes a small,
  documented set of `variant` × `size` × `tone` combinations rather than a sprawl of boolean props or
  copy-pasted components. New look needed → new variant, not a new near-duplicate component.
- Prefer **composition** (`<Card><Card.Header/>…`) over giant prop lists. Composable subcomponents
  beat 20-prop monoliths.
- Sensible defaults: a component used with no props should already look right.

## 6. Accessibility is part of the component, not a later pass
Build primitives on accessible foundations (Radix or equivalent): semantic HTML, keyboard
operability, visible `focus-visible` rings, correct ARIA roles/labels, and `prefers-reduced-motion`
honored in every animation. Verify charcoal/amber combinations meet WCAG AA contrast. An inaccessible
component is an incomplete component. (See `07-engineering-standards.md` for the a11y gate.)

## 7. Responsive & themable by construction
Mobile-first; components adapt via tokens and layout primitives, not per-screen breakpoint hacks.
Charcoal is the dark-first base; if a light theme is ever needed it's a token swap, so never hardcode
a color that would block that.

## 8. A living component gallery
Maintain a showcase where every component renders in isolation with all its variants and states
(Storybook, or a `/dev/ui` route guarded out of prod). This is how you (a) review the kit visually,
(b) catch drift, and (c) onboard. Adding a component without adding it to the gallery is incomplete.

## 9. Each kit component carries a README
Per `06-documentation.md`, a component folder has a short `README.md`: purpose, props/variants, the
states it supports, and a usage example. This is the human + Claude reference and prevents
re-inventing an existing component.

## 10. Performance & hygiene
- Keep primitives lightweight; avoid pulling heavy deps into a low-level component.
- No inline style objects recreated each render for static styles; memoize where it matters.
- Icons from one set (consistent stroke/size); no mixing icon libraries.
- One animation/transition convention (token-driven durations/easing) so motion feels unified.

---

## Definition of done for any UI work
- [ ] Built only from kit components + layout primitives; **zero bespoke visual styling in feature code**
- [ ] Any new element added to the kit as a component/variant (not inlined) and to the gallery
- [ ] All relevant states present: default/hover/active/focus/disabled/**loading**/**error**
- [ ] Loading & feedback rules satisfied (`04-loading-and-feedback.md`)
- [ ] Keyboard-operable, focus-visible, AA contrast, reduced-motion respected
- [ ] Tokens used for every color/space/type/radius/shadow/motion value — no hardcoded values
- [ ] Component README updated/created
