# Feature Specification: starry-background-fix

## 1. Overview
**Summary**: Fix the visibility of the Starry Background component and enhance its visual appeal.
**Rationale**: The previous implementation was not visible due to stacking context and background color issues. The user also requested "cooler" visuals (nebula/glow) and correct theme adaptation.

## 2. User Scenarios
- **Scenario 1**: Global Visibility
  - **Input**: User visits any page (Dashboard, Profile, Login).
  - **Output**: The starry background is visible behind the content.
  - **Constraint**: Content readability must be maintained.

- **Scenario 2**: Theme Adaptation
  - **Input**: User switches themes.
  - **Output**:
    - **Dark Mode**: Deep background with bright, twinkling stars.
    - **Holographic**: Cyberpunk aesthetic with cyan/green hints/glow.
    - **Light Mode**: Subtle dark/blue particles on light background.

## 3. Implementation Details
- **Global Integration**: Move `StarryBackground` to `App.tsx` or a global layout wrapper.
- **CSS Changes**:
  - Apply theme background colors to `body` instead of individual page wrappers.
  - Make page wrappers transparent to let the background show through.
- **Component Enhancements**:
  - Use `position: fixed`.
  - Add "nebula" effects (CSS gradients or Canvas gradients).
  - Adjust star size and density.

## 4. Acceptance Criteria
- [ ] Stars are visible on Dashboard (`HomeTemplate`).
- [ ] Stars are visible on Profile/Account pages (`AppLayout`).
- [ ] Background is fixed during scrolling.
- [ ] Light/Dark mode transitions work visually.
- [ ] Verified via Playwright screenshots showing pixels are present.
