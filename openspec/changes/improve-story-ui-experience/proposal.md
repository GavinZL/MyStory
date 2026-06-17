## Why

MyStory already has the core SwiftUI screens for recording, organizing, and browsing personal stories, but the current UI reads as a functional half-finished app rather than a cohesive memory-recording product. This change turns the existing Timeline, Story Card, Editor, Category, Detail, and Theme foundations into a consistent story-first experience before adding more advanced functionality.

## What Changes

- Redesign the Timeline around a clear "memory timeline" structure with stronger date grouping, story cards, media hierarchy, and empty/search states.
- Refine Story Card presentation so media, text, category, location, and metadata have predictable visual priority across timeline and category-filtered lists.
- Rework the Story Editor into a writing-first composition surface with lightweight media, location, category, AI polish, save-state, and validation affordances.
- Upgrade Category browsing from a raw management tree into a story-line library that supports lightweight organization and discovery.
- Improve full-screen story browsing into a calmer reading and media playback experience with clearer metadata and navigation context.
- Consolidate visual consistency through AppTheme tokens, localized strings, dynamic type behavior, accessibility, and reduced visual noise.
- No breaking data model changes are expected.

## Capabilities

### New Capabilities

- `story-timeline-experience`: Timeline and story card requirements for recording-oriented browsing, search entry, empty states, date grouping, media hierarchy, and metadata display.
- `story-composer-experience`: Story editor requirements for writing-first composition, media attachment, location/category assignment, AI polish entry, save states, and validation.
- `story-browse-experience`: Category and full-screen story browsing requirements for story-line organization, filtered story review, immersive detail reading, and navigation context.
- `ui-theme-consistency`: Cross-screen UI system requirements for AppTheme token usage, localization, dynamic type, accessibility, and consistent interaction feedback.

### Modified Capabilities

- None.

## Impact

- Affected SwiftUI views: `TimelineView`, `StoryCardView`, `NewStoryEditorView`, `CategoryView`, `CategoryCardView`, `CategoryStoryListView`, `FullScreenStoryView`, `SettingsView`, and related shared components.
- Affected shared systems: `AppTheme`, localization files under `Resources/Localizable`, category icon components, media preview components, toast/loading feedback components.
- Affected UX behavior: timeline browsing, story creation/editing, category filtering, full-screen story review, theme switching, font scaling, empty states, and save/error feedback.
- No new third-party dependencies are planned.
