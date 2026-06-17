## ADDED Requirements

### Requirement: Composer prioritizes writing
The system SHALL present story creation and editing as a writing-first composition experience.

#### Scenario: User opens a new story composer
- **WHEN** the user starts creating a new story
- **THEN** the primary focus is the story content editor, with media and metadata tools presented as supporting actions

#### Scenario: User edits an existing story
- **WHEN** the user opens an existing story for editing
- **THEN** the composer restores existing content, media, category, and location while preserving the same writing-first layout

### Requirement: Composer supports lightweight attachment actions
The system SHALL provide clear, localized actions for adding images, video, location, category, and AI polish from the composer.

#### Scenario: User adds media
- **WHEN** the user selects an image or video attachment action
- **THEN** the system opens the appropriate picker and shows selected media previews in a stable layout

#### Scenario: User assigns metadata
- **WHEN** the user chooses location or category controls
- **THEN** the system allows assignment or clearing of that metadata without leaving the composer flow

#### Scenario: User invokes AI polish
- **WHEN** the user selects the AI polish action with editable text available
- **THEN** the system presents the AI polish flow using the current story text as input

### Requirement: Composer communicates save state
The system SHALL communicate whether the story can be saved, is saving, saved successfully, or failed to save.

#### Scenario: New story has no content
- **WHEN** the user has not entered text or attached media in a new story
- **THEN** the save action is disabled or visibly unavailable

#### Scenario: Save succeeds
- **WHEN** the user saves a valid story successfully
- **THEN** the system dismisses or confirms completion and refreshes the originating story list

#### Scenario: Save fails
- **WHEN** story saving or media processing fails
- **THEN** the system shows a localized error message that explains the failure state

### Requirement: Composer uses localized user-facing text
The system SHALL use localized strings for all user-facing composer labels, actions, and status messages.

#### Scenario: App language is Simplified Chinese
- **WHEN** the composer is displayed in Simplified Chinese
- **THEN** all visible composer labels and actions use Simplified Chinese localization keys

#### Scenario: App language is English
- **WHEN** the composer is displayed in English
- **THEN** all visible composer labels and actions use English localization keys
