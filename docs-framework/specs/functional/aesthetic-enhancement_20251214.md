# Feature Specification: aesthetic-enhancement

## 1. Overview
**Summary**: Enhance the aesthetic appeal of the application by improving the starry background (adding constellations, better glow) and applying glassmorphism (transparency/blur) to UI components.
**Rationale**: User feedback indicates that while the background is visible, it is often obscured by opaque cards. The user desires a "cooler" look with constellations, more visible background through gaps/transparency, and richer star effects.

## 2. User Scenarios
- **Scenario 1**: Dashboard Visualization
  - **Input**: User views the dashboard.
  - **Output**: Cards are semi-transparent with a blur effect, revealing the starry background behind them. Gaps between cards are optimized to show more background.
- **Scenario 2**: Starry Background Detail
  - **Input**: User observes the background.
  - **Output**: Stars have varying sizes (some larger/glowing). Constellation lines are faintly visible, connecting specific stars (e.g., Taurus/Capricorn abstraction). The nebula effect is softer and more expansive.

## 3. Implementation Details
- **CSS/Tailwind**:
  - Update `.card` and `.theme-surface` to use `bg-opacity` or `rgba` colors with `backdrop-filter: blur()`.
  - Ensure text readability is maintained despite transparency.
- **StarryBackground Component**:
  - Add `Constellation` logic: predefined points connected by lines.
  - Improve `Star` rendering: `shadowBlur` for glow, larger max radius.
  - Enhance `Nebula` gradients: use multiple overlapping radial gradients with lower opacity.

## 4. Acceptance Criteria
- [ ] Dashboard cards are semi-transparent (glassmorphism).
- [ ] Background is clearly visible through cards and gaps.
- [ ] Constellation patterns are visible (subtle lines connecting stars).
- [ ] Stars appear more dynamic (size variation, glow).
- [ ] Verified via Playwright screenshots and/or Preview.
