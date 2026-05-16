---
name: Epicurean Bento
colors:
  surface: '#f9f9fd'
  surface-dim: '#d9dade'
  surface-bright: '#f9f9fd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f8'
  surface-container: '#ededf2'
  surface-container-high: '#e7e8ec'
  surface-container-highest: '#e2e2e6'
  on-surface: '#191c1f'
  on-surface-variant: '#42474f'
  inverse-surface: '#2e3034'
  inverse-on-surface: '#f0f0f5'
  outline: '#727780'
  outline-variant: '#c2c7d0'
  surface-tint: '#2e6290'
  primary: '#064774'
  on-primary: '#ffffff'
  primary-container: '#2b5f8d'
  on-primary-container: '#b6d8ff'
  inverse-primary: '#9bcbff'
  secondary: '#48654a'
  on-secondary: '#ffffff'
  secondary-container: '#c7e8c6'
  on-secondary-container: '#4c6a4e'
  tertiary: '#5e307a'
  on-tertiary: '#ffffff'
  tertiary-container: '#774894'
  on-tertiary-container: '#edc8ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d0e4ff'
  primary-fixed-dim: '#9bcbff'
  on-primary-fixed: '#001d34'
  on-primary-fixed-variant: '#0c4a76'
  secondary-fixed: '#caebc9'
  secondary-fixed-dim: '#aecfae'
  on-secondary-fixed: '#05210c'
  on-secondary-fixed-variant: '#314d34'
  tertiary-fixed: '#f4d9ff'
  tertiary-fixed-dim: '#e5b5ff'
  on-tertiary-fixed: '#30004b'
  on-tertiary-fixed-variant: '#60327d'
  background: '#f9f9fd'
  on-background: '#191c1f'
  surface-variant: '#e2e2e6'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '900'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-section:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '800'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  title-card:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: '1.4'
    letterSpacing: 0.05em
  body-large:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 1.5rem
  grid-gap: 1.5rem
  section-margin: 2.5rem
  inline-gap: 1rem
  touch-target: 2.5rem
---

## Brand & Style

Epicurean Bento is a high-end food and lifestyle design system that blends **Modern Corporate** reliability with **Editorial Minimalism**. The brand personality is professional, aspirational, and highly organized, targeting home chefs who value clarity and visual beauty.

The UI utilizes a "Bento Box" layout philosophy—grouping related information into distinct, high-contrast containers that vary in size and emphasis. The emotional response should be one of "calm capability," achieved through generous whitespace, crisp typography, and a systematic use of color-coded zones (e.g., primary blues for core actions, secondary greens for utility).

## Colors

The palette is rooted in a sophisticated **Fidelity** logic, where colors are used semantically to distinguish between content types:
- **Primary (Steel Blue):** Used for brand identity, core navigation headers, and primary instructional steps.
- **Secondary (Sage Green):** Reserved for "Success" states and high-momentum action buttons (e.g., "Start Cooking").
- **Tertiary (Amethyst):** Used for informational callouts and specialized tips.
- **Neutrals:** A cool-toned gray scale is used for surfaces and outlines to maintain a clinical, clean environment.

Backgrounds utilize a light-blue tinted white (`#f9f9ff`) to reduce eye strain compared to pure white, while containers use subtle shifts in value to create grouping without heavy borders.

## Typography

The system uses a pairing of **Plus Jakarta Sans** for headlines to provide a modern, welcoming feel, and **Inter** for all functional body and label text to ensure maximum legibility.

Key typographic rules:
- **Hierarchy through Weight:** Use "Black" (900) or "ExtraBold" (800) for primary titles to anchor the page.
- **Micro-Copy:** Use heavy letter spacing and uppercase styling for small labels (like "PREP TIME" or navigation labels) to maintain readability at small scales.
- **Narrative Flow:** Body text uses a comfortable 1.6 line height to facilitate easy reading of long-form instructions.

## Layout & Spacing

The layout follows a **Hybrid Bento Grid** model. On desktop, it utilizes a 12-column grid where the hero image spans 8 columns and utility cards span 4. On mobile, this collapses into a single-column stack with standardized 1rem horizontal margins.

Spacing is governed by a strict 4px/8px baseline:
- **Gaps:** 24px (1.5rem) is the standard gap for major grid items.
- **Internal Padding:** Cards use 24px padding to feel premium and airy.
- **Vertical Rhythm:** Sections are separated by 40px (2.5rem) to provide clear visual breaks between different phases of the user journey (e.g., from Ingredients to Steps).

## Elevation & Depth

Depth is expressed primarily through **Tonal Layering** rather than traditional shadows, supplemented by subtle ambient lifts for interactive elements:

- **Level 0 (Base):** Surface color (`#f9f9ff`).
- **Level 1 (Cards):** White containers with a 1px `outline-variant` border.
- **Level 2 (Interactive):** `shadow-sm` or `shadow-md` applied to buttons and primary hero elements to suggest they are "above" the informational grid.
- **Overlays:** A 60% black-to-transparent gradient is used on images to ensure text legibility without requiring solid backing shapes.
- **Backdrop:** The bottom navigation uses a `backdrop-blur-md` with 80% opacity to maintain context while providing a clear functional layer.

## Shapes

The shape language is **Rounded**, moving away from "soft" into a more distinct, approachable geometry:
- **Standard Cards:** 0.75rem (rounded-xl) for a modern, friendly appearance.
- **Action Elements:** 1rem (rounded-2xl) or "Full" for buttons and chips to signify touchability.
- **Checkboxes:** 0.375rem (rounded-md) to balance the circular icons with a more structured container.
- **Hero Containers:** 1rem (rounded-2xl) to create a soft frame for photography.

## Components

### Buttons
- **Primary Action:** Large, full-width blocks with `secondary-container` backgrounds, bold icons, and heavy 18px text.
- **Icon Buttons:** Circular 40px targets with subtle hover states (light gray tint) and centered Material Symbols.

### Cards & Bento Items
- **Informational:** Use `primary-container` for high-impact stats. Icons should be placed in 20% opacity white squares to create a "glass" icon-container effect.
- **Ingredient Items:** Row-based with 1px borders, featuring a custom checkbox-style indicator on the left.

### Instructions (Step Lists)
- **Numbered Indicators:** 48px circles using the `primary` color.
- **Connector:** A 1px vertical line connects sequential steps to guide the eye downward.

### Navigation
- **Bottom Bar:** A floating-effect bar with centered icon-label pairs. The active state is indicated by a rounded-xl container background behind the icon.
- **Top Bar:** Sticky, white background, featuring a simple back-arrow and title for task-focused screens.