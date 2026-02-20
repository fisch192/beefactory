# 05. The Figma Auto-Layout Expert
**Role:** Design Ops Specialist at Figma + Frontend Design Expert
**Brand:** Beefactory

## FRAME STRUCTURE
- **Page Organization:** 
  1. `[Void Canvas]` (1440x900 default, Fill: `#0A0A0A`)
  2. `[Nav_Monolith]`
  3. `[Hero_Section_FullBleed]`
  4. `[Data_Grid_Asymmetrical]`
- **Grid System Setup:** 
  - 12 columns, Gutter: 24, Margin: 80.
  - Type: Stretch.

## AUTO-LAYOUT SPECIFICATIONS

### The "Engineered Button" (Component: `Btn_Amber`)
- **Direction:** Horizontal
- **Padding:** Top: 16px, Bottom: 16px, Left: 32px, Right: 32px
- **Spacing between items:** 12px
- **Distribution:** Packed (Center)
- **Alignment:** Center Middle
- **Resizing constraints:** Hug contents (H), Hug contents (W)
- **Corner Radius:** 0px (Absolute Sharpness)
- **Fill:** `#FFB400`
- **Stroke:** None

### The "Product Data Token" (Component: `Card_Machined`)
- **Direction:** Vertical
- **Padding:** Top: 32px, Bottom: 32px, Left: 32px, Right: 32px
- **Spacing between items:** 24px
- **Distribution:** Packed (Top)
- **Alignment:** Top Left
- **Resizing constraints:** Fill container (W), Hug contents (H)
- **Corner Radius:** 0px
- **Fill:** `#1C1C1E`
- **Effect:** Inner Shadow (Y: 1px, Blur: 0, Color: `#FFFFFF` @ 4% opacity) - acts as a machined highlight.

### The "Data Row" (Inside `Card_Machined`)
- **Direction:** Horizontal
- **Padding:** 0px
- **Spacing between items:** Auto
- **Distribution:** Space-between
- **Alignment:** Center Middle
- **Resizing constraints:** Fill container (W)
- **Left Label:** `JetBrains Mono` / Steel Gray (`#8E8E93`) / 16px
- **Right Value:** `JetBrains Mono` / Titanium White (`#F5F5F7`) / 16px

## COMPONENT ARCHITECTURE
- **Master Component:** `Btn_Base`
- **Variants Hierarchy:**
  - *Tier 1 (Type):* Primary (Fill), Secondary (Outline), Ghost (Text).
  - *Tier 2 (State):* Default, Hover, Active, Disabled, Loading (with pure CSS-style spinner icon).
  - *Tier 3 (Size):* Sm (H: 32px), Md (H: 48px), Lg (H: 64px - Massive hit area).
- **Component Properties:**
  - `Label text` (Text property linked to all variants)
  - `Show Icon Left` (Boolean)
  - `Show Icon Right` (Boolean)
  - `Icon Swap` (Instance swap)

## DESIGN TOKEN INTEGRATION (Figma Variables Setup)
### Color Variables (Collection: `Industrial Core`)
- `color-bg-base`: `#0A0A0A`
- `color-surface-elevated`: `#1C1C1E`
- `color-brand-primary`: `#FFB400`
- `color-brand-secondary`: `#CC9000`
- `color-text-high`: `#F5F5F7`
- `color-text-low`: `#8E8E93`

### Number Variables (Collection: `Technical Spacing`)
- `space-micro`: 4px, `space-base`: 16px, `space-macro`: 64px, `space-void`: 192px.

## PROTOTYPE CONNECTIONS
- **Interaction Map:** The checkout flow is a single vertical descent.
- **Trigger Type:** `On Click` moves to next state.
- **Animation Specs:** 
  - *Type:* Smart Animate
  - *Easing Curve:* Custom Spring (`stiffness: 300`, `damping: 30`). The motion should snap hard like a mechanical latch, not drift floatily like generic UI.
  - *Duration:* 300ms.

## DEVELOPER HANDOFF PREPARATION
- **Asset Naming Convention:** `kebab-case`. `icon-cart`, `hero-macro-hive-01.webp`.
- **CSS Export Verification:** Everything is built using standard Flexbox paradigms in Auto-Layout. `Gap` maps to `gap`. `Padding` maps to `padding`. No absolute positioning (`Constraints` disabled).

## ACCESSIBILITY ANNOTATIONS (A11y Layer in Figma)
- A separate auto-layout frame floats above the design containing red-lined focus order (1, 2, 3...) mapped to `tabindex`.
- Contrast checks pass automatically due to the Void Black vs. Titanium White/Raw Amber paradigm.
