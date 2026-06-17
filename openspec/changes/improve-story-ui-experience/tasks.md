## 1. UI Foundation And Localization

- [x] 1.1 Audit touched SwiftUI files for hardcoded user-facing strings, system visual defaults, hardcoded spacing, hardcoded typography, and hardcoded colors.
- [x] 1.2 Add missing localization keys for redesigned Timeline, Story Card, Composer, Category, Detail, empty states, status messages, and error feedback in English and Simplified Chinese.
- [x] 1.3 Extend `AppTheme` only where existing tokens are insufficient for timeline axis, metadata chips, composer tool rows, card borders, and interaction states.
- [x] 1.4 Update shared reusable components to prefer `AppTheme` tokens and accessibility labels for icon-only controls.

## 2. Timeline And Story Card Experience

- [x] 2.1 Add Timeline empty state with localized copy and a create-first-story action.
- [x] 2.2 Add a visible Timeline search entry that routes to the existing or planned search experience.
- [x] 2.3 Redesign Timeline date presentation to show clear chronological context with stable spacing and a subtle memory-timeline structure.
- [x] 2.4 Refactor `StoryCardView` into deterministic media-first and text-first presentation rules.
- [x] 2.5 Update story metadata display to use compact category and location treatments with localized separators and category navigation preserved.
- [x] 2.6 Ensure media grid presentation uses stable image/video sizing rules for one image, two images, three-to-nine images, and video thumbnails.

## 3. Story Composer Experience

- [x] 3.1 Rework `NewStoryEditorView` layout so story text input is the primary first-screen surface.
- [x] 3.2 Replace hardcoded composer labels such as image library, video, done, and custom icon copy with localized strings.
- [x] 3.3 Present image, video, location, category, and AI polish actions as lightweight composer tools with clear icons and accessibility labels.
- [x] 3.4 Improve composer save-state feedback for disabled, saving, success, and failure states.
- [x] 3.5 Verify editing an existing story restores content, media, location, and category without changing the writing-first layout.

## 4. Category And Full-Screen Browsing

- [x] 4.1 Redesign `CategoryCardView` to use `AppTheme` tokens and present top-level categories as story collections.
- [x] 4.2 Keep category list mode dense and management-oriented while aligning row styling with the redesigned theme system.
- [x] 4.3 Update category story lists to reuse Timeline story card and date presentation rules while hiding redundant category metadata when appropriate.
- [x] 4.4 Add or refine category empty state with localized create-first-story action scoped to the selected category.
- [x] 4.5 Refine `FullScreenStoryView` and story detail surfaces so media stories, text-only stories, metadata, and paging context remain readable and calm.

## 5. Accessibility, Dynamic Type, And Visual Verification

- [ ] 5.1 Verify redesigned Timeline, Composer, Category, Detail, and Settings surfaces at standard, large, and extra-large font scale settings.
- [ ] 5.2 Verify light, dark, and at least one warm/non-default theme across redesigned surfaces.
- [x] 5.3 Add accessibility labels and traits for icon-only create, close, save, media, location, category, AI polish, play, and search controls.
- [ ] 5.4 Confirm long category names, long locations, text-only stories, media-heavy stories, and empty states do not overlap or truncate incoherently.

## 6. Build And Regression Checks

- [ ] 6.1 Run `xcodebuild -project MyStory.xcodeproj -scheme MyStory -configuration Debug build`.
- [ ] 6.2 Run available tests with `xcodebuild -project MyStory.xcodeproj -scheme MyStory test` if the scheme has tests configured.
- [ ] 6.3 Manually smoke test story creation, story editing, media attachment, category assignment, location assignment, timeline browsing, category browsing, full-screen story review, theme switching, language switching, and font scaling.
- [x] 6.4 Review changed files for project style compliance: file headers where applicable, MARK sections, MVVM separation, `AppTheme` usage, and localized user-facing strings.
