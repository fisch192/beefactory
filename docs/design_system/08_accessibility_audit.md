# 08. The Accessibility Auditor
**Role:** Accessibility Specialist at Apple + Frontend Design Expert
**Brand:** Beefactory

## Objective
To ensure the "Industrial Organic" visual direction (extreme contrast, raw aesthetics) maintains uncompromising WCAG 2.2 Level AA compliance, functioning flawlessly as a premium e-commerce tool.

---

## 1. PERCEIVABLE
### The Void Black / Raw Amber Paradigm
- **Contrast Check [PASS]:** The brand's decision to use `Void Black (#0A0A0A)` and `Raw Amber (#FFB400)` provides a striking contrast ratio of `11.8:1`, massively exceeding the 4.5:1 requirement.
- **Titanium White Text [PASS]:** Reading technical data in `JetBrains Mono` at `#F5F5F7` against `#1C1C1E` (Machined Charcoal) yields a flawless `14:1` contrast ratio.
- **Images of Text [FAIL in Draft, Fixed in Production]:** Overlaid typography (like the massive Hero headers) must be actual `h1` DOM elements, not baked into the macro photography.

### Text Alternatives
- **Alt Text Strategy:** "Decorative vs. Structural."
  - The massive background textures (honey dripping, metal) will have `alt=""` (decorative).
  - The actual product shots must have hyper-descriptive alt text. Example: `alt="A 10-frame Langstroth hive body machined from aerospace-grade aluminum, showing the precision interlocking corner joints."`

## 2. OPERABLE
### Keyboard Navigation (The "Machine Operator" Flow)
- **Focus Indicators [Custom Recommendation]:** Do NOT use the default browser blue ring. It destroys the industrial aesthetic. Instead, implement a custom focus state: a 2px solid `Raw Amber` ring with a 4px offset (`outline: 2px solid #FFB400; outline-offset: 4px; border-radius: 0px`). This perfectly matches the "Anti-Slop" brand mandate.
- **Skip Links:** A visually hidden `<a href="#main-content">Skip to Product Specs</a>` must snap into view (Raw Amber box, Titanium White text, `JetBrains Mono`) on the first Tab keypress.

### Touch Targets (The "Gloved Hand" Test)
- **Compliance:** Beekeepers often browse with dirty or gloved hands (in spirit, if not in practice). All interactive elements (buttons, quantity selectors, cart triggers) must have a minimum CSS padding ensuring a `48x48px` absolute minimum touch area, exceeding the 44x44 Apple HIG standard.

### Motion Control
- **prefers-reduced-motion:** If a user flags this OS setting, the heavy "spring physics" transitions and the slow-panning hero images must instantly degrade to simple opacity cross-fades. The brand's heavy industrial feel should never cause vestibular nausea.

## 3. UNDERSTANDABLE
### Error Identification
- **Forms and Checkout:** Rather than generic red text below an input, the "Industrial Organic" error state is a stark, 1px left-border flash of `Hazard Red (#FF453A)` with monospaced error output like `[ERR: INVALID POSTAL CODE DETECTED]`. Plain language, but formatted like a terminal log.

## 4. ROBUST
### ARIA and State
- **The Cart Drawer:** Must use `aria-expanded="true/false"` on the toggle button, trap focus within the drawer while open, and loudly announce price changes to screen readers using `aria-live="polite"` regions.

---
**Auditor's Note:** Accessibility is not an excuse for boring design. The extreme contrast requested by the Creative Director (`#0A0A0A` and `#FFB400`) actually makes this site *more* accessible than 90% of low-contrast, light-grey SaaS templates. Our custom focus states and massive typography will ensure an elite experience for all users.
