# Calendar Screen Refactoring Strategy

## Overview
The `calendar_screen.dart` file is currently **4,513 lines** long and handles multiple responsibilities. This document outlines a comprehensive strategy to refactor it into maintainable, testable components while preserving all existing functionality and visuals.

## Current Issues
- **Single Responsibility Violation**: One file handling calendar display, event management, shift calculations, settings, navigation, and data loading
- **Difficult Maintenance**: Hard to locate and fix bugs in such a large file
- **Testing Challenges**: Difficult to test individual components in isolation
- **Team Development**: Merge conflicts and difficulty for multiple developers to work simultaneously
- **Performance**: Large widget rebuilds affecting performance

## Identified Responsibility Areas

### 1. Calendar Display Logic
- TableCalendar widget management
- Day rendering and styling
- Month/year navigation
- Calendar state management

### 2. Event Management
- Event CRUD operations
- Event dialogs (add, edit, delete)
- Event display and filtering
- Event validation

### 3. Shift Management
- Shift calculations and roster logic
- Shift number loading
- Shift time calculations
- Rest days management

### 4. Settings Management
- First-run setup dialog
- Settings persistence
- Start date and week configuration

### 5. Navigation
- Drawer menu
- Navigation to various screens (statistics, settings, etc.)
- Page routing

### 6. Data Loading & Caching
- Holiday loading
- Bank holiday management
- Event preloading
- Cache management

### 7. UI State Management
- Animation controllers
- Selected day state
- Loading states
- Error handling

### 8. Dialog Management
- Multiple complex dialogs
- Dialog state management
- User input validation

## Refactoring Strategy

### Phase 1: Extract Smaller Widgets

#### 1.1 Calendar Header Widget
**File**: `lib/features/calendar/widgets/calendar_header.dart`
**Responsibilities**:
- Month/year display
- Navigation arrows
- Month/year picker dialog
- Header styling

#### 1.2 Calendar Body Widget
**File**: `lib/features/calendar/widgets/calendar_body.dart`
**Responsibilities**:
- TableCalendar widget
- Day cell rendering
- Event markers
- Calendar styling and theming

#### 1.3 Events List Widget
**File**: `lib/features/calendar/widgets/events_list_widget.dart`
**Responsibilities**:
- Daily events display
- Event cards rendering
- Event interaction handling
- Empty state display

#### 1.4 App Drawer Widget
**File**: `lib/features/calendar/widgets/app_drawer_widget.dart`
**Responsibilities**:
- Navigation drawer
- Menu items
- User profile section
- Drawer styling

#### 1.5 Floating Action Button Widget
**File**: `lib/features/calendar/widgets/calendar_fab.dart`
**Responsibilities**:
- Add event button
- FAB positioning
- Animation handling

### Phase 2: Extract Business Logic

#### 2.1 Calendar Controller
**File**: `lib/features/calendar/controllers/calendar_controller.dart`
**Responsibilities**:
- Calendar state management
- Date navigation logic
- Event filtering and sorting
- Focus day management
- Selected day handling

```dart
class CalendarController extends ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _startDate;
  int _startWeek = 0;
  int _selectedYear = DateTime.now().year;
  
  // Getters and methods for state management
}
```

#### 2.2 Event Dialog Manager
**File**: `lib/features/calendar/managers/dialog_manager.dart`
**Responsibilities**:
- Handle all event-related dialogs
- Dialog state management
- User input validation
- Dialog result processing

#### 2.3 Shift Calculator
**File**: `lib/features/calendar/utils/shift_calculator.dart`
**Responsibilities**:
- Shift number calculations
- Roster logic
- Shift time calculations
- Rest days determination

#### 2.4 Settings Manager
**File**: `lib/features/calendar/managers/settings_manager.dart`
**Responsibilities**:
- First-run setup
- Settings persistence
- Configuration management
- Initial setup dialogs

#### 2.5 Navigation Handler
**File**: `lib/features/calendar/managers/navigation_handler.dart`
**Responsibilities**:
- Handle navigation to other screens
- Route management
- Navigation state

### Phase 3: Extract Data Management

#### 3.1 Calendar Data Repository
**File**: `lib/features/calendar/repositories/calendar_data_repository.dart`
**Responsibilities**:
- Centralize all data loading
- Handle caching logic
- Data synchronization
- Error handling

#### 3.2 Event Repository
**File**: `lib/features/calendar/repositories/event_repository.dart`
**Responsibilities**:
- Event CRUD operations
- Event persistence
- Event validation
- Event synchronization

#### 3.3 Holiday Repository
**File**: `lib/features/calendar/repositories/holiday_repository.dart`
**Responsibilities**:
- Holiday management
- Bank holiday loading
- Holiday persistence
- Holiday calculations

## Proposed File Structure

```
lib/features/calendar/
├── screens/
│   └── calendar_screen.dart (coordinator widget - ~200-300 lines)
├── controllers/
│   └── calendar_controller.dart
├── managers/
│   ├── dialog_manager.dart
│   ├── settings_manager.dart
│   └── navigation_handler.dart
├── repositories/
│   ├── calendar_data_repository.dart
│   ├── event_repository.dart
│   └── holiday_repository.dart
├── widgets/
│   ├── calendar_header.dart
│   ├── calendar_body.dart
│   ├── events_list_widget.dart
│   ├── app_drawer_widget.dart
│   └── calendar_fab.dart
└── utils/
    └── shift_calculator.dart
```

## Migration Strategy (Zero-Downtime Approach)

### Step 1: Preparation
1. **Create feature branch**: `git checkout -b refactor/calendar-screen`
2. **Backup original file**: Keep `calendar_screen.dart` intact during refactoring
3. **Set up testing**: Ensure existing tests pass before starting

### Step 2: Extract Utilities First (Lowest Risk)
1. Create `shift_calculator.dart`
2. Move shift calculation methods
3. Test functionality
4. Update imports in main file

### Step 3: Extract Repositories (Data Layer)
1. Create repository files
2. Move data loading methods
3. Test data operations
4. Update main file to use repositories

### Step 4: Extract Controllers (Business Logic)
1. Create controller files
2. Move state management logic
3. Test state changes
4. Connect controller to main screen

### Step 5: Extract Managers (Dialog & Navigation)
1. Create manager files
2. Move dialog and navigation methods
3. Test user interactions
4. Update main file to use managers

### Step 6: Extract Widgets (UI Components)
1. Create widget files one by one
2. Move UI building methods
3. Test visual appearance and interactions
4. Replace sections in main file incrementally

### Step 7: Final Cleanup
1. Refactor main `calendar_screen.dart` into coordinator
2. Remove unused imports and methods
3. Add comprehensive tests
4. Update documentation

## Testing Strategy

### Unit Tests
- **Controllers**: Test state management logic
- **Repositories**: Test data operations
- **Utils**: Test calculation functions
- **Managers**: Test business logic

### Widget Tests
- **Individual Widgets**: Test each extracted widget
- **Integration**: Test widget interactions
- **Visual Tests**: Ensure UI remains identical

### Integration Tests
- **Full Flow**: Test complete calendar functionality
- **Navigation**: Test screen transitions
- **Data Flow**: Test end-to-end data operations

## Verification Checklist

### Functionality Preservation
- [ ] Calendar navigation works identically
- [ ] Event creation/editing/deletion functions the same
- [ ] Shift calculations remain accurate
- [ ] Settings management unchanged
- [ ] All dialogs work as before
- [ ] Navigation to other screens works
- [ ] Data loading and caching work correctly

### Performance Verification
- [ ] App startup time unchanged or improved
- [ ] Calendar scrolling performance maintained
- [ ] Memory usage not increased
- [ ] Widget rebuild optimization working

### Code Quality Improvements
- [ ] Each file has single responsibility
- [ ] Code is more readable and maintainable
- [ ] Tests cover all major functionality
- [ ] Documentation is updated

## Benefits After Refactoring

### Maintainability
- **Single Responsibility**: Each file has one clear purpose
- **Bug Location**: Easier to find and fix issues
- **Code Understanding**: New developers can understand components quickly

### Testability
- **Unit Testing**: Individual components can be tested in isolation
- **Mocking**: Dependencies can be easily mocked
- **Test Coverage**: Better test coverage possible

### Performance
- **Widget Rebuilds**: Smaller widgets rebuild more efficiently
- **Memory Usage**: Better memory management
- **Loading Times**: Optimized data loading

### Team Development
- **Parallel Work**: Multiple developers can work on different components
- **Merge Conflicts**: Reduced conflicts due to smaller files
- **Code Reviews**: Easier to review smaller, focused changes

## Risk Mitigation

### Low-Risk Approach
1. **Incremental Changes**: Make small changes and test frequently
2. **Feature Branch**: Work in isolation until complete
3. **Rollback Plan**: Keep original file until fully tested
4. **Comprehensive Testing**: Test each component thoroughly

### Monitoring
- **Functionality Tests**: Run after each extraction
- **Performance Tests**: Monitor app performance throughout
- **User Testing**: Test with real usage patterns

## Timeline Estimate

### Phase 1: Preparation & Setup (1-2 days)
- Set up branch and testing
- Analyze dependencies
- Create file structure

### Phase 2: Extract Utilities & Repositories (2-3 days)
- Low-risk extractions first
- Test data operations

### Phase 3: Extract Controllers & Managers (3-4 days)
- Business logic extraction
- Test state management

### Phase 4: Extract Widgets (4-5 days)
- UI component extraction
- Visual testing

### Phase 5: Testing & Cleanup (2-3 days)
- Comprehensive testing
- Documentation updates
- Final cleanup

**Total Estimated Time: 12-17 days**

## Notes
- Preserve all existing functionality and visuals
- Test thoroughly at each step
- Consider performance implications
- Update documentation as you go
- Get code reviews for major changes

---

This refactoring will transform a monolithic 4,513-line file into manageable, maintainable components while preserving all existing functionality. 