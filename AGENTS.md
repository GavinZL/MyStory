# AGENTS.md - MyStory iOS Project Guidelines

## Project Overview
- **Type**: iOS Swift/SwiftUI Application
- **Language**: Swift 5.9+
- **Minimum iOS Version**: 16.0+
- **Architecture**: MVVM + Router Pattern
- **Storage**: Core Data (local)

## Build Commands

### Build
```bash
# Build using xcodebuild
xcodebuild -project MyStory.xcodeproj -scheme MyStory -configuration Debug build

# Build for Release
xcodebuild -project MyStory.xcodeproj -scheme MyStory -configuration Release build
```

### Clean
```bash
xcodebuild -project MyStory.xcodeproj clean
```

### Test (if tests exist)
```bash
# Run all tests
xcodebuild -project MyStory.xcodeproj -scheme MyStory test

# Run single test file
xcodebuild -project MyStory.xcodeproj -scheme MyStory -only-testing:MyStoryTests/TestFileName test

# Run specific test
xcodebuild -project MyStory.xcodeproj -scheme MyStory -only-testing:MyStoryTests/TestFileName/testMethodName test
```

### Simulator
```bash
# Run on iPhone 15 Simulator
xcodebuild -project MyStory.xcodeproj -scheme MyStory -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Code Style Guidelines

### Naming Conventions
- **Files**: PascalCase (e.g., `TimelineView.swift`, `AppRouter.swift`)
- **Classes/Structs/Enums**: PascalCase (e.g., `StoryViewModel`, `AppRoute`)
- **Variables/Properties**: camelCase (e.g., `storyList`, `isLoading`)
- **Constants**: camelCase (e.g., `maxCacheSize`, `defaultTimeout`)
- **Functions**: camelCase with verb prefix (e.g., `navigateTo()`, `loadData()`)
- **Protocol**: PascalCase with descriptive name (e.g., `CategoryServiceProtocol`)

### File Organization
```
// 1. File header comment
//
//  Filename.swift
//  MyStory
//
//  Brief description of the file's purpose
//

// 2. Imports
import SwiftUI
import Foundation

// 3. MARK sections for organization
// MARK: - Types/Enums
// MARK: - Main Class/Struct
// MARK: - Properties
// MARK: - Methods
// MARK: - Private Methods

// 4. Preview provider (for SwiftUI Views)
#Preview {
    ViewName()
}
```

### Imports
- Import only what you need
- Group imports: Foundation first, then SwiftUI, then other frameworks
- No wildcard imports

### Comments
- File header with description
- Use `// MARK: -` to organize sections
- Document public APIs with brief descriptions
- Add inline comments for complex logic

### SwiftUI Patterns
- Use `@StateObject` for view-owned objects
- Use `@ObservedObject` for injected dependencies
- Use `@EnvironmentObject` for shared dependencies (router, theme)
- Use `@Environment` for system values (managedObjectContext)
- Prefer `NavigationStack` over deprecated `NavigationView`

### MVVM Architecture
```swift
// View - thin, declarative
struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    // View logic only, no business logic
}

// ViewModel - business logic, ObservableObject
class TimelineViewModel: ObservableObject {
    @Published var stories: [StoryModel] = []
    // Business logic, data transformation
}
```

### Theme System (REQUIRED)
All UI values must use `AppTheme` tokens - NO magic numbers:

```swift
// ✅ CORRECT - Use theme tokens
.background(AppTheme.Colors.surface)
.font(AppTheme.Typography.body)
.padding(AppTheme.Spacing.m)
.cornerRadius(AppTheme.Radius.m)

// ❌ WRONG - No hardcoded values
.background(Color.gray)
.font(.system(size: 17))
.padding(16)
.cornerRadius(12)
```

**Available Tokens:**
- `AppTheme.Colors.primary/background/surface/textPrimary/textSecondary/border/success/warning/error`
- `AppTheme.Typography.largeTitle/title1/title2/title3/headline/body/callout/subheadline/footnote/caption`
- `AppTheme.Spacing.xs/s/m/l/xl/xxl` (4/8/12/16/24/32)
- `AppTheme.Radius.s/m/l` (8/12/16)
- `AppTheme.Shadow.small/medium/large`

### Localization (REQUIRED)
All user-facing strings must be localized:

```swift
// ✅ CORRECT - Use localization
Text("story.title.placeholder".localized)
Label("tab.timeline".localized, systemImage: "clock.fill")

// ❌ WRONG - No hardcoded strings
Text("请输入标题")
Label("时间轴", systemImage: "clock.fill")
```

**Localization Pattern:**
- Keys: `module.context.name` (e.g., `common.cancel`, `settings.theme.title`)
- Extension: Use `.localized` property on String
- Files: Located in `Resources/Localizable/en.lproj/` and `zh-Hans.lproj/`

### Component Reuse
**ALWAYS check existing components before creating new ones:**
- `Components/` - Shared UI components
- `Utils/` - Helper extensions and utilities
- Check `AppTheme.swift` for styling needs

### Error Handling
```swift
// Use Result type for async operations
func fetchData() async -> Result<[StoryModel], Error> {
    do {
        let data = try await service.fetch()
        return .success(data)
    } catch {
        return .failure(error)
    }
}

// Handle errors in UI with alert or toast
```

### Router Navigation
```swift
// Use AppRouter for all navigation
@EnvironmentObject var router: AppRouter

// Push navigation
router.navigate(to: .storyDetail(storyId: id))

// Present sheet
router.presentSheet(.aiPolish(text: content))

// Go back
router.navigateBack()
```

### File Structure
```
MyStory/
├── App/                      # App entry point
├── Core/
│   ├── Router/              # Navigation routing
│   ├── Storage/             # Core Data stack
│   └── Network/             # Network layer
├── Models/
│   ├── Entities/            # Core Data entities
│   ├── ViewModels/          # Business models
│   └── Category/            # Other models
├── Services/                # Business services
├── Views/                   # SwiftUI views (by feature)
├── ViewModels/              # SwiftUI view models
├── Components/              # Reusable components
├── Utils/                   # Extensions and utilities
└── Resources/               # Assets, localization
```

## Code Review Checklist
- [ ] No hardcoded colors/spacing/fonts (use AppTheme)
- [ ] No hardcoded strings (use localization)
- [ ] Proper MARK sections
- [ ] File header comment present
- [ ] Preview provider for views
- [ ] Follows MVVM pattern
- [ ] Uses existing components if available
- [ ] Supports dark mode (via theme system)
- [ ] Accessibility considerations
