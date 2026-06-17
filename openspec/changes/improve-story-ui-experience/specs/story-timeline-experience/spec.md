## ADDED Requirements

### Requirement: Timeline presents stories as a memory timeline
The system SHALL present the main Timeline as a chronological memory surface with visually distinct date context and story content.

#### Scenario: Story list renders with date context
- **WHEN** the user opens the Timeline with existing stories
- **THEN** each visible story entry shows a date context, a story card, and a clear visual relationship between the date and the story content

#### Scenario: Timeline supports long-list scanning
- **WHEN** the user scrolls through many Timeline entries
- **THEN** story entries remain visually scannable without heavy repeated shadows or inconsistent spacing

### Requirement: Story cards prioritize media and text predictably
The system SHALL render story cards with predictable media-first and text-first variants based on the story content.

#### Scenario: Story has media attachments
- **WHEN** a story contains one or more image or video attachments
- **THEN** the card gives media primary visual priority while preserving readable story text and metadata

#### Scenario: Story has no media attachments
- **WHEN** a story contains text but no image or video attachments
- **THEN** the card gives text primary visual priority with sufficient whitespace and readable line spacing

### Requirement: Story cards expose compact metadata
The system SHALL show category and location metadata as compact secondary information on story cards.

#### Scenario: Story has category and location metadata
- **WHEN** a story has category and location metadata
- **THEN** the card displays the metadata below the primary story content without competing with the media or text hierarchy

#### Scenario: Story category is tapped
- **WHEN** the user taps the category metadata on a story card
- **THEN** the app navigates to the relevant category-filtered story list

### Requirement: Timeline provides empty and search entry states
The system SHALL provide clear affordances for first-use empty state and story search entry from the Timeline surface.

#### Scenario: No stories exist
- **WHEN** the user opens Timeline and no stories exist
- **THEN** the system shows an empty state that invites creating the first story

#### Scenario: User wants to find an existing story
- **WHEN** the user is on the Timeline
- **THEN** the system provides a visible search entry for finding stories by content, location, or category
