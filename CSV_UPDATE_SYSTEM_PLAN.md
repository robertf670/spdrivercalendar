# CSV Update System - Implementation Plan

## Overview
Enable remote updating of duty CSV files via Firebase Storage without requiring app updates. Updates are rare (only when duty errors are found) but should be delivered immediately to users.

## Requirements
- ✅ Immediate updates when CSV changes detected
- ✅ Works offline with cached/bundled fallback
- ✅ Simple upload workflow (Firebase Console)
- ✅ Manual "Check for Updates" in settings
- ✅ Background check on app startup
- ❌ No analytics needed
- ❌ No admin panel needed
- ❌ No per-file versioning complexity

---

## Architecture

### File Storage Structure (Firebase Storage)
```
firebase_storage://
└── csv_files/
    ├── version.json                    # Single timestamp for all files
    ├── M-F_DUTIES_PZ1.csv
    ├── M-F_DUTIES_PZ3.csv
    ├── M-F_DUTIES_PZ4.csv
    ├── SAT_DUTIES_PZ1.csv
    ├── SAT_DUTIES_PZ3.csv
    ├── SAT_DUTIES_PZ4.csv
    ├── SUN_DUTIES_PZ1.csv
    ├── SUN_DUTIES_PZ3.csv
    ├── SUN_DUTIES_PZ4.csv
    ├── M-F_ROUTE2324.csv
    ├── SAT_ROUTE2324.csv
    ├── SUN_ROUTE2324.csv
    ├── UNI_M-F.csv
    ├── UNI_7DAYs.csv
    ├── JAMESTOWN_DUTIES.csv
    ├── training_duties.csv
    ├── buscheck.csv
    └── ... (all duty CSVs)
```

### version.json Format
```json
{
  "timestamp": "2025-10-22T14:30:00Z",
  "description": "Updated 4/39 duty times"
}
```

### Local Cache Structure
```
app_documents_directory/
└── cached_csvs/
    ├── version.json                    # Local copy of version info
    ├── M-F_DUTIES_PZ1.csv
    ├── M-F_DUTIES_PZ3.csv
    └── ... (all downloaded CSVs)
```

### File Resolution Priority
1. **Local Cache** (`cached_csvs/`) - Downloaded from Firebase
2. **Bundled Assets** (`assets/`) - Fallback if no cache
3. **Error Handling** - Graceful fallback if downloads fail

---

## Implementation Steps

### Phase 1: Setup Firebase Storage (One-time)

**Firebase Console Steps:**
1. Navigate to Firebase Console → Storage
2. Create folder: `csv_files/`
3. Upload all current CSV files from `assets/` folder:
   - All `*_DUTIES_*.csv` files
   - All `*_ROUTE*.csv` files  
   - `buscheck.csv`, `training_duties.csv`, etc.
4. Create `version.json` with initial timestamp:
   ```json
   {
     "timestamp": "2025-10-22T00:00:00Z",
     "description": "Initial CSV data"
   }
   ```
5. Set storage rules (allow read for authenticated users)

**Storage Rules:**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /csv_files/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins via Console
    }
  }
}
```

### Phase 2: Create CSV Update Service

**New File:** `lib/services/csv_update_service.dart`

**Class Methods:**
- `init()` - Initialize service, setup cache directory
- `checkForUpdates()` - Compare local vs remote version
- `downloadAllCsvs()` - Download all CSVs from Firebase
- `loadCsvFile(String filename)` - Load CSV (cache → assets → error)
- `getCachedVersion()` - Read local version.json
- `getRemoteVersion()` - Fetch remote version.json
- `clearCache()` - Delete cached CSVs (troubleshooting)
- `getLastUpdateTime()` - For UI display
- `getLastCheckTime()` - For UI display

**Key Features:**
- Async/await for all operations
- Error handling with fallback to assets
- Cache validation (check file exists before using)
- Download progress tracking (optional for UI)
- Atomic updates (download to temp, then rename)

### Phase 3: Modify Existing CSV Loading Logic

**Files to Update:**

1. **`lib/features/calendar/services/roster_service.dart`**
   - Find all: `await rootBundle.loadString('assets/...')`
   - Replace with: `await CsvUpdateService.instance.loadCsvFile('...')`
   - Examples:
     - `'assets/M-F_DUTIES_PZ1.csv'` → `'M-F_DUTIES_PZ1.csv'`
     - `'assets/SAT_DUTIES_PZ1.csv'` → `'SAT_DUTIES_PZ1.csv'`

2. **`lib/services/board_service.dart`**
   - Same CSV loading changes
   - Update all zone board file loading

3. **`lib/features/calendar/services/route_service.dart`**
   - Update route CSV loading
   - Cache invalidation when CSVs update

4. **`lib/services/bus_check_service.dart`**
   - Update buscheck.csv loading

5. **Any other services loading CSV files**
   - Search codebase for: `rootBundle.loadString('assets/*.csv')`
   - Update all occurrences

**Pattern to Follow:**
```dart
// OLD:
final data = await rootBundle.loadString('assets/M-F_DUTIES_PZ1.csv');

// NEW:
final data = await CsvUpdateService.instance.loadCsvFile('M-F_DUTIES_PZ1.csv');
```

### Phase 4: Add Startup Check

**File:** `lib/main.dart`

**Add to main():**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing Firebase init ...
  
  // Initialize CSV update service
  await CsvUpdateService.instance.init();
  
  // Check for updates in background (non-blocking)
  CsvUpdateService.instance.checkForUpdates().catchError((error) {
    // Log error but don't block app startup
    print('CSV update check failed: $error');
  });
  
  runApp(MyApp());
}
```

**Behavior:**
- Non-blocking: App starts immediately
- Background check completes in 1-3 seconds
- Downloads happen silently
- Errors are logged but don't affect app startup

### Phase 5: Add Settings UI

**File:** `lib/features/settings/settings_screen.dart` (or wherever settings are)

**Add Section:**
```
CSV Data Management
├── Last Updated: 3 days ago
├── Last Checked: 2 minutes ago
├── [Check for Updates] button
└── [Clear Cache & Re-download] button (troubleshooting)
```

**UI Elements:**
- Show last update timestamp from cached version.json
- Show last check timestamp from shared preferences
- "Check for Updates" button with loading state
- Status messages: "Up to date", "Downloading...", "Updated successfully"
- Optional: "Clear Cache" for troubleshooting

**User Feedback:**
- Show snackbar on successful update: "Duty data updated"
- Show error if download fails: "Update failed. Using cached data."
- Show progress indicator during download

### Phase 6: Testing

**Test Scenarios:**

1. **Fresh Install (No Cache)**
   - Delete app data
   - Install app
   - Should use bundled assets
   - Background check should download CSVs
   - Next app restart uses cached CSVs

2. **Update Available**
   - Upload new CSV to Firebase
   - Update version.json timestamp
   - Open app or click "Check for Updates"
   - Should download new CSVs
   - Verify new data appears in calendar

3. **Offline Mode**
   - Disable wifi/mobile data
   - Open app
   - Should use cached CSVs (if available)
   - Should fallback to bundled assets (if no cache)
   - No errors or crashes

4. **Download Failure**
   - Simulate network error during download
   - Should keep using old cached version
   - Should show error message
   - Should not corrupt cache

5. **Corrupted Cache**
   - Manually corrupt a cached CSV file
   - Open app
   - Should detect corruption
   - Should re-download or fallback to assets

6. **Cache Clear**
   - Click "Clear Cache" in settings
   - Should delete all cached CSVs
   - Should re-download on next check
   - Should use bundled assets until download completes

---

## Your Update Workflow

### When a Duty Error is Found

**Steps:**
1. Open CSV file locally (e.g., `M-F_DUTIES_PZ1.csv`)
2. Fix the error (update times, locations, etc.)
3. Go to Firebase Console → Storage → `csv_files/`
4. Upload corrected CSV file (overwrites old one)
5. Edit `version.json`:
   - Update timestamp to current time
   - Optionally update description
6. Upload `version.json`

**Time Required:** ~2 minutes

**User Experience:**
- Next time users open app: Update downloads automatically
- Or users can click "Check for Updates" in settings
- Changes take effect immediately (or after app restart)

### Bulk Updates (Multiple CSVs)

**If updating multiple files:**
1. Fix all CSV files locally
2. Upload all changed CSVs to Firebase
3. Update version.json once (with combined description)
4. One timestamp update = all files download

---

## Technical Decisions & Rationale

### Why Download All CSVs (Not Individual Files)?

**Pros:**
- Simpler logic (one timestamp)
- Avoids version conflicts between files
- Total size is still small (~500KB for all CSVs)
- Ensures data consistency

**Cons:**
- Downloads unchanged files (minimal impact)

**Decision:** Download all CSVs on any version change. Simplicity > optimization.

### Why Firebase Storage (Not Firestore)?

**Pros:**
- Files stay as CSVs (easy to edit)
- Existing parsing logic unchanged
- Simple upload via Console
- No migration needed

**Cons:**
- Not "real-time" updates (requires app restart)

**Decision:** Firebase Storage is sufficient for rare updates.

### Why Timestamp (Not Semantic Versioning)?

**Pros:**
- Simpler (just compare dates)
- Auto-generated (current time)
- No manual version incrementing

**Cons:**
- No version numbers (1.0, 1.1, etc.)

**Decision:** Timestamp is adequate for infrequent updates.

### Why Background Startup Check (Not Only Manual)?

**Pros:**
- Users get updates automatically
- No need to remember to check
- Silent, non-intrusive

**Cons:**
- Slight startup delay (~1 second)

**Decision:** Non-blocking background check on startup + manual option.

---

## Dependencies

**Required Packages** (check if already in pubspec.yaml):
- ✅ `firebase_storage` - For Firebase Storage access
- ✅ `path_provider` - For local cache directory
- ✅ `shared_preferences` - For last check timestamp
- ✅ `http` - For downloading files

**Firebase Configuration:**
- Firebase Storage must be enabled in project
- Storage rules must allow read access

---

## Error Handling Strategy

### Network Errors
- **Symptom:** No internet connection during check
- **Handling:** Silently fail, use cached/bundled CSVs
- **User Message:** None (or "Could not check for updates")

### Download Failures
- **Symptom:** Timeout, incomplete download, corrupted file
- **Handling:** Rollback to previous cached version or assets
- **User Message:** "Update failed. Using cached data."

### Parse Errors
- **Symptom:** Downloaded CSV is malformed
- **Handling:** Detect during load, fallback to assets
- **User Message:** "Data error. Using default data."

### Cache Corruption
- **Symptom:** Cached file is corrupted
- **Handling:** Delete corrupt file, re-download or use assets
- **User Message:** "Cache error. Re-downloading data."

### Firebase Storage Down
- **Symptom:** Firebase service unavailable
- **Handling:** Use cached/bundled CSVs
- **User Message:** None (silent fallback)

---

## Performance Considerations

### Startup Time
- Background check adds ~1 second (non-blocking)
- Download happens after app is usable
- User doesn't notice impact

### Data Size
- All CSVs combined: ~500KB
- Download time: 1-3 seconds on typical connection
- Negligible storage impact

### Cache Management
- Cache persists across app restarts
- No automatic cleanup needed (CSVs are small)
- Manual clear option in settings

### Memory Usage
- CSVs loaded on-demand (not all at once)
- Existing parsing logic unchanged
- No additional memory overhead

---

## Future Enhancements (Not Implemented Now)

### Possible Additions:
1. **Push Notifications**
   - Notify users when critical updates available
   - Requires Firebase Cloud Messaging

2. **Diff/Delta Updates**
   - Only download changed files
   - Requires per-file versioning

3. **Rollback Feature**
   - Keep previous version in cache
   - Allow reverting to old data

4. **Update History**
   - Log all updates with descriptions
   - Show in settings

5. **Admin Panel**
   - Web interface for uploading CSVs
   - No need for Firebase Console

6. **Automatic Restart Prompt**
   - Offer to restart app after critical updates
   - Requires update severity flag

7. **Data Validation**
   - Verify CSV format before saving
   - Reject malformed data

---

## Open Questions / Decisions Needed

### 1. Startup Behavior
**Options:**
- A) Silent background check, no UI indication
- B) Show subtle loading indicator "Checking for updates..."
- C) Only manual checks (no automatic startup check)

**Recommendation:** Option A (silent background check)

### 2. Update Notification
**Options:**
- A) Silent download, just works next time
- B) Show toast/snackbar "Duty data updated"
- C) Prompt user to restart app for changes

**Recommendation:** Option B (show snackbar notification)

### 3. Cache Invalidation
**Should there be a "Clear Cache & Re-download" option in settings?**

**Recommendation:** Yes, for troubleshooting

### 4. Update Requirement
**Should the app force download updates or work with old cached data?**

**Recommendation:** Optional updates, always work offline

---

## Implementation Checklist

### Pre-Development
- [ ] Enable Firebase Storage in Firebase Console
- [ ] Create `csv_files/` folder structure
- [ ] Upload all current CSVs to Firebase Storage
- [ ] Create initial `version.json`
- [ ] Configure Storage security rules

### Development
- [ ] Create `csv_update_service.dart`
- [ ] Implement version checking logic
- [ ] Implement download logic with error handling
- [ ] Implement cache management
- [ ] Update `roster_service.dart` CSV loading
- [ ] Update `board_service.dart` CSV loading
- [ ] Update `route_service.dart` CSV loading
- [ ] Update `bus_check_service.dart` CSV loading
- [ ] Search and update all other CSV loading calls
- [ ] Add startup check to `main.dart`
- [ ] Add settings UI section
- [ ] Add "Check for Updates" button
- [ ] Add "Clear Cache" button
- [ ] Add status displays (last updated, last checked)

### Testing
- [ ] Test fresh install (no cache)
- [ ] Test update download
- [ ] Test offline mode (no internet)
- [ ] Test download failure scenarios
- [ ] Test corrupted cache
- [ ] Test cache clear functionality
- [ ] Test with multiple CSV updates
- [ ] Test startup performance impact

### Documentation
- [ ] Update changelog for new version
- [ ] Add user documentation (how to check for updates)
- [ ] Document Firebase Storage structure
- [ ] Document your update workflow

### Deployment
- [ ] Test on Android build
- [ ] Test on iOS build (if applicable)
- [ ] Verify Firebase Storage permissions
- [ ] Create release notes
- [ ] Update version number
- [ ] Build and release

---

## Estimated Timeline

**Implementation:** 6-8 hours
- CSV Update Service: 3-4 hours
- Modify existing services: 2-3 hours
- Settings UI: 1-2 hours

**Testing:** 2-3 hours
- Unit tests: 1 hour
- Integration testing: 1-2 hours

**Documentation & Deployment:** 1 hour

**Total:** ~10-12 hours of focused development

---

## Risk Assessment

### Low Risk
- ✅ Firebase Storage reliability
- ✅ CSV file size (very small)
- ✅ Existing code structure supports changes
- ✅ Fallback mechanism (bundled assets)

### Medium Risk
- ⚠️ Network errors during download (handled with fallback)
- ⚠️ Cache corruption (handled with re-download)
- ⚠️ Testing all edge cases (requires thorough testing)

### High Risk
- ❌ None identified

---

## Success Criteria

### Functional
- ✅ CSVs can be updated remotely without app release
- ✅ Users receive updates within next app launch
- ✅ App works offline with cached data
- ✅ No crashes or errors during update process

### Performance
- ✅ Startup time impact < 2 seconds
- ✅ Download completes in < 5 seconds on typical connection
- ✅ Memory usage unchanged

### Usability
- ✅ Update process is invisible to users (or minimal notification)
- ✅ Manual update check available in settings
- ✅ Clear status indicators (last updated, etc.)

### Maintainability
- ✅ Simple upload workflow (Firebase Console)
- ✅ Update time < 3 minutes
- ✅ No complex deployment process

---

## Notes

- This feature is designed for **rare, immediate updates** (not frequent changes)
- Prioritizes **simplicity over optimization** (download all CSVs vs. individual files)
- Prioritizes **reliability** (always have working data via fallback)
- No breaking changes to existing CSV format or structure
- Can be implemented incrementally (core feature first, UI enhancements later)

---

## Version History

- **v1.0** (2025-10-22) - Initial plan created

