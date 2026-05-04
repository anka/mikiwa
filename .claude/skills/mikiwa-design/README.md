# Mikiwa Design System

A design system for the new **Mikiwa** Kindergarten-Verwaltungsplattform — a web application for kindergarten administrators (Betreuer:innen) and parents (Eltern). Light + dark variants, warm pastel accents, modern but trust-building tone.

## About Mikiwa

**MIKIWA — Mit Kindern wachsen** ("Growing with Children") is a kindergarten / Kindergruppe in Feldkirchen, Kärnten (Austria). The new platform serves two audiences:

- **Betreuer:innen / Verwaltung** — managing the kindergarten: organisation, attendance lists, staff coordination, calendar.
- **Eltern** — receiving information, signing up for events, viewing the calendar, communicating with caregivers.

### Brand pillars
- **Vertrauen** (trust) — parents are entrusting their children
- **Wärme & Geborgenheit** — warmth and safety
- **Wachsen** — growth, development, individual care
- **Miteinander** — community, open collaboration
- **Spielerisch, aber seriös** — playful but professional. Not childish; it's parents and staff using the tool, not children.

### Core values from the original site
> "Materialarbeit · Stilleübungen · Waldtage · Kreatives · Bewegung · Singen"
>
> "Grenzen und Regeln eingehalten werden, damit sich die Kinder in einer entspannten Atmosphäre, in Geborgenheit und Sicherheit weiterentwickeln können"
>
> Montessori-orientiert, Waldtage, Kreatives, Rollenspiel, Bewegung.

### Sources & references
- Live website: https://mikiwa.at — used as the brand-source. Distinctive elements: handprint-sunflower logo by Tine Ulbing, children's drawings, photographs by Günter Krammer.
- Address: Gurktalerstrasse 16, 9560 Feldkirchen in Kärnten, Österreich
- Note: web fetching of mikiwa.at returned only the page title in this environment. The visual derivation here is therefore an *informed interpretation* of the brand brief (warm, pastel, modern, trust-building) rather than a pixel-extraction. **See "Caveats" at the bottom.**

---

## Index

| File | Purpose |
|---|---|
| `README.md` | This file. Brand context, content + visual fundamentals, iconography. |
| `colors_and_type.css` | Design tokens — colors (light + dark) and type scale. |
| `SKILL.md` | Agent-skill manifest for downstream use. |
| `fonts/` | Web fonts (Nunito for display + body, JetBrains Mono for code). |
| `assets/` | Logos, icon set, brand illustrations. |
| `preview/` | Design-system preview cards (Type, Colors, Spacing, Components, Brand). |
| `ui_kits/webapp/` | UI kit for the new admin + parent web application. |

---

## Content Fundamentals

### Language
- **Primary language: German (de-AT)** — Austrian German conventions where they exist. The original site uses standard German with regional warmth.
- Date/time formats: `Mo, 04.05.2026`, `09:00–13:00`. Currency: `€ 4,50`.

### Voice & Tone
- **Warm, direct, respectful.** Speaking to professionals (Betreuer:innen) AND families. Not babyish.
- **Gender-fair forms** with `:` (`Betreuer:innen`, `Eltern`, `Kinder`, `Kolleg:innen`) — neutral, modern Austrian/German standard.
- **Anrede: "Sie"** in default UI copy (parents are guests; staff are colleagues addressed formally). Switch to **"du"** only inside team-internal areas if needed.
- Active voice. Short sentences. No marketing fluff, no exclamation marks except in genuine celebratory moments (Geburtstag, Sommerfest).

### Casing
- Sentence case for all UI labels and buttons: `Anwesenheit eintragen`, not `Anwesenheit Eintragen`.
- Nouns capitalized per German rules: `Kalender`, `Kind`, `Gruppe`.
- Section/page titles: also sentence case, larger weight.

### Examples
| Context | ✅ Yes | ❌ No |
|---|---|---|
| Empty state | "Heute sind noch keine Kinder eingetragen." | "Oh nein! Hier ist es noch leer 🥺" |
| Confirmation | "Anwesenheit gespeichert." | "Yay, gespeichert! 🎉" |
| Error | "Bitte wählen Sie ein Datum." | "Ups — das hat nicht geklappt." |
| Button | "Eintrag speichern" | "JETZT SPEICHERN!" |
| Greeting (parent) | "Guten Morgen, Familie Huber" | "Hallo Mama Huber 👋" |
| Greeting (staff) | "Guten Morgen, Sabine" | (same — first name OK for staff) |

### Emoji
- **Emoji are not part of the UI language.** The brand uses children's drawings and photographs, not emoji. Reserve emoji for *user-generated content* (parent messages, comments).

---

## Visual Foundations

### Palette
Warm, modern pastels rooted in nature — sun (Sonnenblume), earth, sky, leaf — toned down for adult professional UIs. Not Crayola; not grayscale corporate. Think: a sunny kindergarten morning seen by a calm grown-up.

- **Primary — Sonnengelb (`--accent`)**: warm honey/amber. Echoes the sunflower logo. Used for primary actions, brand accents, today-markers.
- **Secondary — Wiesengrün**: soft sage. Growth, nature, Waldtage. Used for success, attendance-OK, calendar accents.
- **Tertiary — Himmelblau**: dusty soft blue. Trust, calm. Used for informational accents, links.
- **Wärmender Korall**: muted terracotta/coral. Attention, important without alarm.
- **Beerenrot**: berry red, only for destructive/alert states (rare).
- **Neutrals**: warm off-whites and warm browns/grays — never pure cold gray. The "papier" feel.
- **Dark mode**: deep warm charcoal (slight aubergine undertone), with the same accents desaturated by ~10% for night-friendly contrast.

All values + semantic mappings live in `colors_and_type.css`.

### Type
- **Display + UI: Nunito** (Google Fonts). Round, friendly, highly legible at small sizes; warm without being cartoonish. Available 300–900.
- **Mono / data: JetBrains Mono** for code, IDs, technical strings.
- **No serif.** Serifs felt too editorial for this product.
- Scale follows a 1.2 minor-third ratio with explicit semantic vars (h1…h6, body, caption, mono).
- **FONT SUBSTITUTION FLAG:** The original mikiwa.at site uses default WordPress theme fonts. Nunito was chosen as the closest warm-yet-professional Google Font. **→ User: please confirm or supply preferred font files.**

### Spacing & Layout
- Base unit: **4px**. Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 96.
- Generous whitespace — the product should feel calm, not crowded.
- Containers max-width 1200px; sidebars 264px desktop / collapsible mobile.

### Corner radii
Soft, never sharp. `--radius-sm: 6px` (chips, small buttons), `--radius-md: 10px` (inputs, cards), `--radius-lg: 16px` (panels, modals), `--radius-pill: 999px` (status pills, avatars, primary CTAs). Slightly rounder than typical SaaS — the product carries warmth.

### Cards
Single elevation: subtle, not floating.
- Background: `--surface` (paper warm-white in light, warm-charcoal in dark).
- Border: 1px hairline `--border-subtle` (always visible — defines edges in both modes).
- Shadow: `0 1px 2px rgba(80, 60, 30, 0.04), 0 4px 12px rgba(80, 60, 30, 0.06)` (warm-tinted, not gray).
- Radius: `--radius-lg`.
- Hover lift: shadow strengthens, never translateY (movement is reserved for purposeful interactions).

### Backgrounds
- **Surface:** plain warm-white / warm-charcoal. No gradients on functional surfaces.
- **Marketing / hero / login splash:** soft radial wash of the pastel palette (sun-yellow → sky-blue) at very low opacity, plus an optional decorative "child's drawing" SVG corner-mark.
- **No textures, no grain, no pattern repeats** in the app. Cleanliness = trust.
- Use real **photographs** from MIKIWA / Günter Krammer where available; otherwise children's drawing motifs (Sonnenblume, Handabdruck) used sparingly as accents, never as repeating patterns.

### Borders & dividers
- Hairline `1px` `--border-subtle` (warm, low-contrast).
- Strong `1px` `--border-strong` only for focused/selected states.
- Never use box-shadow as a divider replacement.

### Shadows (full system)
- `--shadow-xs` — chip / pill float.
- `--shadow-sm` — default card (see above).
- `--shadow-md` — popover / dropdown.
- `--shadow-lg` — modal / dialog.
- `--shadow-focus` — focus ring (accent-tinted, not blue browser default).

All warm-tinted (`rgba(80,60,30,…)` light; `rgba(0,0,0,…)` dark).

### Animation
- Easings: `--ease-soft: cubic-bezier(.25,.46,.45,.94)` for entries, `--ease-bounce: cubic-bezier(.34,1.4,.64,1)` for confirmations only (success toast, attendance-marked).
- Durations: `120ms` micro (hover), `200ms` standard (panel open, dropdown), `350ms` page transition.
- **Fades + small Y translates (4–8px).** No big slides. No parallax. No looping ambient animation.
- Reduced-motion: collapse all transforms to opacity-only.

### Hover & press states
- **Hover (clickable surface):** background shifts to `--surface-hover` (a 4% warm tint).
- **Hover (filled button):** color darkens by ~6% (oklch L−.04). Never lightens.
- **Press:** scale to `0.98` for 80ms, paired with the darker color. Tactile but subtle.
- **Focus:** 2px outline in `--accent`, 2px offset. Always visible for keyboard.
- **Disabled:** 50% opacity + `cursor: not-allowed`. No graying — keeps the warmth.

### Transparency & blur
- **Blur is rare.** Used only on the mobile bottom-nav sticky bar (`backdrop-filter: blur(12px)` over a 70%-opaque surface) and on the modal scrim (`backdrop-filter: blur(2px) + rgba(0,0,0,.4)`).
- Functional content is always opaque.

### Imagery vibe
Warm, daylight, slightly desaturated. Real photographs of children/activities, never stock posed shots. Children's drawings are *flat colored fills* in the same pastel palette. No black-and-white, no heavy grain, no duotones.

### Layout rules (fixed elements)
- Top app bar: 64px, sticky, opaque.
- Left sidebar (desktop): 264px, fixed, scrolls independently.
- Mobile bottom-nav: 64px + safe-area-inset-bottom, blurred translucent.
- All other content scrolls within the page region.

---

## Page actions — placement metaphor

Every full-page screen follows the same action-bar pattern (derived from the existing mikiwa Sommerfest detail page). The page header is *always* a single horizontal row at the top: title on the left, all actions on the right. **There is no separate "actions" panel further down the page.**

```
┌────────────────────────────────────────────────────────────────────┐
│ Title                       [destructive] [secondary] [PRIMARY] [↩]│
│ Optional subtitle / metadata                                       │
└────────────────────────────────────────────────────────────────────┘
```

### Rules

1. **One primary per page.** Only ever one filled or outlined button. Everything else is a ghost text+icon button.
2. **Right alignment, single row.** Actions are stacked horizontally and right-aligned. They never wrap into a card or sidebar.
3. **Order, left → right:** destructive (`Absagen`, `Löschen`) → secondary actions (`Teilen`, `Duplizieren`) → primary (`Bearbeiten` / `Speichern`) → `Zurück` (always rightmost).
4. **Icons left of label**, 14px, same color as the label text. No icon on `Zurück`.
5. **Destructive ghost buttons use `--danger` for color**, not red fills. Loud reds are reserved for confirmation dialogs.
6. **`Zurück`** is a ghost button with no icon, identical visual weight to other secondaries — nothing more.

### Per-page-type defaults

| Page type | Primary | Secondary (left of primary) | Right edge |
|---|---|---|---|
| **List** (e.g. `/kinder`) | `+ Kind hinzufügen` (filled outline) | — | — |
| **Detail / view** (e.g. `/kinder/lena`) | `✎ Bearbeiten` | `× Absagen` (danger), `↗ Teilen` | `Zurück` |
| **New / edit form** | `✓ Speichern` | `Abbrechen` (ghost) | — |
| **Settings (no save needed)** | — | — | `Zurück` |

### Why no kebab menu?

Mikiwa is used by busy pedagogues with one hand on a child's shoulder. **Hidden actions in a `⋯` menu cost a click and a hunt.** The action row is generous enough to fit 3–4 visible actions; if you have more than that, the page is doing too much — split it.

The component lives in `ui_kits/webapp/PageHeader.jsx` and is used by every staff-side page.

---

## Iconography

**Approach: outline-style, single-stroke, rounded.** Matches the soft warm tone — no filled-glyph severity, no two-tone Duotone, no cartoon icons.

- **Primary set: Lucide Icons** (CDN: `https://unpkg.com/lucide@latest`). Open source, 1.5px stroke, rounded line-caps — exact match for the desired warmth-meets-clarity.
- **Stroke:** `1.75px` for sizes ≥20px, `1.5px` ≤16px.
- **Sizes:** 16, 20, 24 (default), 32. Use `currentColor` so they tint with text color.
- **No emoji in UI chrome.**
- **Custom marks** — the **Sonnenblume mit Handabdrücken** (sunflower with handprints) is the brand mark. A simplified mono SVG version lives in `assets/logo-mikiwa.svg`. Children's-drawing illustrations may appear as decorative empty-state graphics only, never as functional icons.
- **Unicode:** OK for typographic punctuation (`·`, `–`, `…`, `→`) but never as a substitute for icons.

**Substitution flag:** Lucide is a CDN substitute; the original site has no documented icon system. → User: confirm Lucide is acceptable, or supply your own set.

---

## Caveats & open questions for the user

1. **Web fetch of mikiwa.at returned only the page title in this environment.** I worked from the brief + search snippets + brand pillars. Please drop screenshots of the existing site (homepage, about, gallery) — or re-attach assets — so I can tighten color extraction, especially the exact yellow/green of the handprint-sunflower mark.
2. **Logo:** I have not been able to download the actual `Sonnenblume mit Handabdrücken` graphic (created by Tine Ulbing). I've placed an interpretive placeholder in `assets/logo-mikiwa.svg`. **→ Please supply the original SVG/PNG.**
3. **Fonts:** Nunito chosen as a Google-Fonts substitute. Confirm or replace.
4. **Tone:** I defaulted to "Sie" for parents, first-name for staff. Confirm.
5. **Icons:** Lucide chosen. Confirm.
6. **Dark mode:** I designed it warm-charcoal. Please confirm you want a true dark mode and not just a "dimmed" mode — they look different.

**Once you've confirmed these and dropped any real assets, I'll iterate to tighten the system.**
