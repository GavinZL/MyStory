## ADDED Requirements

### Requirement: UI uses AppTheme tokens
The system SHALL use `AppTheme` tokens for user-facing UI colors, typography, spacing, radius, shadows, icon sizes, opacity, gradients, and animation values in redesigned surfaces.

#### Scenario: Theme changes
- **WHEN** the user changes the app theme
- **THEN** redesigned Timeline, Story Card, Composer, Category, Detail, and Settings surfaces update consistently without hardcoded visual values overriding the selected theme

#### Scenario: A redesigned component needs styling
- **WHEN** a redesigned component needs color, typography, spacing, corner radius, shadow, or icon size values
- **THEN** the component uses existing or newly added `AppTheme` tokens instead of unrelated hardcoded values

### Requirement: UI supports dynamic font scaling
The system SHALL support the existing font scale setting and avoid layout breakage in redesigned surfaces.

#### Scenario: User selects large font scale
- **WHEN** the user selects a larger font scale
- **THEN** redesigned story cards, metadata rows, composer controls, category rows, and settings rows remain readable without incoherent overlap

### Requirement: UI uses localized strings
The system SHALL localize all user-facing strings introduced or touched by the redesigned surfaces.

#### Scenario: User switches language
- **WHEN** the user switches between English and Simplified Chinese
- **THEN** redesigned labels, buttons, empty states, status messages, and alerts display the selected language

### Requirement: UI provides accessible controls and feedback
The system SHALL provide accessible labels, clear tap targets, and visible feedback for redesigned interactive controls.

#### Scenario: User interacts with icon-only controls
- **WHEN** a redesigned surface contains an icon-only control
- **THEN** the control has an accessibility label and a tap target suitable for iOS touch interaction

#### Scenario: User performs a long-running action
- **WHEN** media import, location lookup, AI polish, save, or cache cleanup is in progress
- **THEN** the system shows clear localized progress feedback and prevents duplicate conflicting actions where appropriate
