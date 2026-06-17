## ADDED Requirements

### Requirement: Category browsing presents story collections
The system SHALL present categories as story collections and story lines rather than only raw management rows.

#### Scenario: User opens Category tab in card mode
- **WHEN** the user opens the Category tab in card mode
- **THEN** top-level categories display as collection cards with icon, name, story count, and child category context

#### Scenario: User opens Category tab in list mode
- **WHEN** the user switches to list mode
- **THEN** categories display as a dense hierarchical list suitable for management and navigation

### Requirement: Category story lists reuse timeline story presentation
The system SHALL display category-filtered stories using the same story card and date presentation rules as Timeline, adjusted for category context.

#### Scenario: Category contains stories
- **WHEN** the user opens a category with stories
- **THEN** the category story list shows those stories using consistent card, media, text, and date styling

#### Scenario: Category contains no stories
- **WHEN** the user opens a category with no stories
- **THEN** the system shows an empty state with an action to create the first story in that category

### Requirement: Full-screen browsing supports immersive story review
The system SHALL provide a full-screen story browsing experience for focused review of story media, text, and metadata.

#### Scenario: Story has media
- **WHEN** the user opens a media story in full-screen browsing
- **THEN** the media receives primary visual focus while text and metadata remain available and readable

#### Scenario: Story has no media
- **WHEN** the user opens a text-only story in full-screen browsing
- **THEN** the text receives primary visual focus with comfortable reading spacing

#### Scenario: User pages between stories
- **WHEN** the user navigates between stories in full-screen browsing
- **THEN** the system preserves clear date or title context for the currently visible story

### Requirement: Story metadata supports navigation context
The system SHALL allow story metadata in browsing contexts to help users understand and navigate story relationships.

#### Scenario: User taps category metadata in detail browsing
- **WHEN** the user taps category metadata on a story detail surface
- **THEN** the system navigates to the relevant category story list when available
