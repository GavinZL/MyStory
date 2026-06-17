## Context

MyStory is an iOS 16+ SwiftUI application for recording and managing personal stories with Core Data local storage, media attachments, location metadata, three-level categories, localization, and an existing `AppTheme` system. The app already has the main surfaces needed for the product: `TimelineView`, `StoryCardView`, `NewStoryEditorView`, category management views, settings, full-screen story browsing, and supporting theme/localization utilities.

The current implementation is functional but visually fragmented. Timeline entries, story cards, editor controls, category cards, settings rows, and full-screen detail views use a mix of theme tokens, system defaults, hardcoded dimensions, hardcoded strings, and varied information hierarchy. This change is a cross-cutting UI/UX refinement that keeps the current app architecture and data model intact while tightening the user-facing experience.

## Goals / Non-Goals

**Goals:**

- Establish Timeline as the primary daily recording and review surface.
- Make Story Cards consistently prioritize content, media, category, location, and time metadata.
- Make Story Editor feel like a writing-first composition surface with lightweight tools.
- Position Category as a story-line/library browsing surface rather than a raw management utility.
- Improve full-screen browsing for calm story review and media playback.
- Ensure the redesigned UI consistently uses `AppTheme`, localized strings, dynamic type support, and accessible controls.

**Non-Goals:**

- Do not change Core Data entities or migration behavior.
- Do not introduce new third-party UI dependencies.
- Do not implement cloud sync, account systems, sharing, comments, likes, or collaborative features.
- Do not redesign privacy/support/legal document content.
- Do not replace the existing MVVM + Router structure.

## Decisions

### Decision: Keep the existing three-tab information architecture

The app will keep `Timeline`, `Category`, and `Settings` as the primary tabs. Timeline remains the main user workflow for capture and review, Category becomes an organization and retrieval surface, and Settings remains utility-focused.

Alternative considered: Add a separate center "Compose" tab. This would improve capture visibility but would also introduce navigation churn and duplicate the existing Timeline plus button flow. The current app can get most of the benefit by making the Timeline create action more prominent and improving the editor launch experience.

### Decision: Use "memory timeline" as the main visual metaphor

Timeline entries will be organized around date grouping, a subtle timeline axis, and story cards. Cards will avoid heavy shadows in long lists and use stable spacing, border, and surface treatments from `AppTheme`.

Alternative considered: Full masonry or social-feed layout. That would emphasize media but weakens chronological storytelling, which is central to this product's positioning.

### Decision: Make media-first and text-first story cards deterministic

Story cards will use predictable variants: media-first cards when images/videos exist, text-first cards when no media exists, and compact metadata at the bottom. This avoids one generic card trying to serve all content states equally.

Alternative considered: Let each card dynamically size and reorder content freely. That creates visual variety but makes long-list scanning and dynamic type behavior less reliable.

### Decision: Treat Story Editor as a composition surface, not a form

The editor will keep the existing save/close/date structure but place writing content first, then lightweight media/location/category/AI controls. Metadata controls should be visible without dominating the first screen.

Alternative considered: Build a multi-step creation flow. That would reduce visual density but slow down quick capture, which is a core daily use case.

### Decision: Keep Category management powerful but reduce its default visual weight

Category should support existing creation, editing, moving, deletion, search, and hierarchical browsing, but the default card mode should frame categories as story collections and story lines. List mode remains for dense management.

Alternative considered: Remove list/card mode choice and force one simplified layout. Existing functionality suggests both casual browsing and management workflows are valuable, so the redesign should clarify rather than remove them.

### Decision: Centralize all visual and text consistency through existing systems

The implementation will use `AppTheme` for colors, typography, spacing, radius, shadows, icon sizes, opacity, gradients, and animations. User-facing strings must be localized. Dynamic font scaling must not break card, toolbar, or metadata layouts.

Alternative considered: Use native SwiftUI defaults for low-level controls. This is faster locally but undermines theme switching, dark mode, and the project's explicit style rules.

## Risks / Trade-offs

- [Risk] The scope touches many screens and may create regressions in navigation or sheet presentation. -> Mitigation: Implement in small screen-level phases and build after each phase.
- [Risk] Reducing shadows and moving to quieter surfaces may initially feel less visually rich. -> Mitigation: Use media hierarchy, date treatment, selected states, and theme accents to preserve polish without visual clutter.
- [Risk] Dynamic type can break dense timeline metadata and category rows. -> Mitigation: Use flexible stacks, line limits only where appropriate, minimum scale factors only for compact labels, and preview/testing at large font scales.
- [Risk] Localizing all remaining hardcoded strings can expand scope. -> Mitigation: Start with user-visible strings in touched UI files and add both English and Simplified Chinese keys in the same change.
- [Risk] Existing media thumbnails may vary in aspect ratio and cause unstable list heights. -> Mitigation: Define fixed card media presentation rules and use clipping/fit behavior consistently by media count.

## Migration Plan

1. Apply UI changes behind existing view structure without data model changes.
2. Update localized strings in both `en.lproj` and `zh-Hans.lproj` when touching user-facing labels.
3. Build the app after each major surface: Timeline/Card, Editor, Category/Detail, Theme consistency.
4. If a UI phase creates unacceptable regressions, revert the affected view/component changes without storage migration or data recovery work.

## Open Questions

- Should the Timeline create action remain only in the navigation bar, or become a larger floating/action affordance after the first UI pass?
- Should the app keep all seven existing themes after cleanup, or reduce the visible presets to three higher-quality themes?
- Should "三级分类" be renamed in UI copy to "故事线" while preserving the underlying category model names?
