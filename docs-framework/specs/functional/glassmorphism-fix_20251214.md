# Feature Spec: Glassmorphism Fix

## 1. Background
The user reported that the glassmorphism effect (transparency and blur) is not working as expected. The starry background is likely obscured by multiple layers of semi-opaque backgrounds, and the blur effect is weak.

## 2. Goals
- **Enhance Transparency**: Significantly reduce the opacity of UI containers (Cards, Headers, Surface) to allow the starry background to show through clearly.
- **Strengthen Blur**: Increase `backdrop-filter: blur()` values to create a stronger frosted glass effect.
- **Remove Blocking Layers**: Identify and remove any intermediate wrapper `div`s that might have default solid backgrounds.
- **Consistency**: Ensure the effect works across Dark, Light, and Holographic themes.

## 3. Technical Implementation

### 3.1. CSS Updates (`index.css`)
- **`.theme-surface`**:
  - Change opacity mix from `70%` to `40%` (or lower).
  - Increase blur to `20px`.
- **`.card`**:
  - Change opacity mix from `60%` to `30%`.
  - Increase blur to `24px`.
  - Ensure border is also semi-transparent.
- **Global Variables**:
  - Ensure `var(--surface)` for Holographic theme is compatible with `color-mix` or adjust it directly.

### 3.2. Component Cleanup
- **`HomeTemplate.tsx`**:
  - Remove redundant `bg-opacity` classes that might conflict with `theme-surface`.
  - Ensure the header uses the updated glass style.
- **`Navigation.tsx`**:
  - Check `bg-[var(--surface)]/50` usage. Replace with `.theme-surface` class for consistency.

## 4. Verification Plan
- **Visual Check (Playwright)**:
  - Verify computed `background-color` has low alpha (e.g., < 0.5).
  - Verify `backdrop-filter` is applied.
  - Take a screenshot (internal validation).

