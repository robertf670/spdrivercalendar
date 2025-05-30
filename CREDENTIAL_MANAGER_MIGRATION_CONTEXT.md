# Credential Manager Migration Context

## Current Problem Summary

### Issue Description
- **Local Development**: Google Calendar sign-in works perfectly with `flutter run --debug`
- **GitHub Actions APKs**: Google Calendar sign-in fails with "sign in cancelled or failed" error
- **Root Cause**: Google is deprecating legacy Google Sign-In APIs and restricting them in CI/CD environments

### Technical Details
- **Current Package**: `google_sign_in: ^6.2.1` (legacy API)
- **Error Code**: DEVELOPER_ERROR (code 10) in GitHub-built APKs
- **SHA-1 Fingerprints**: Verified consistent across all builds
- **OAuth Configuration**: Properly configured in Google Cloud Console
- **Firebase Setup**: Correctly configured with proper google-services.json

### What We've Tried
1. ✅ Fixed SHA-1 fingerprint consistency between local and GitHub builds
2. ✅ Cleaned up OAuth client configurations in Google Cloud Console
3. ✅ Verified Firebase configuration with correct SHA-1 fingerprints
4. ✅ Tested with and without `serverClientId` parameter
5. ❌ GitHub APKs still fail despite all configuration fixes

### Conclusion
The issue is **environment-specific**, not configuration-specific. Google's legacy APIs are being restricted in automated build environments.

## Migration Plan: Google Sign-In → Credential Manager

### Why Credential Manager?
- **Google's Recommended Approach**: Modern authentication standard
- **CI/CD Friendly**: Designed to work in automated build environments
- **Future-Proof**: Google's long-term authentication strategy
- **Better Security**: Modern authentication standards and protocols

### Current Architecture

#### Dependencies (pubspec.yaml)
```yaml
dependencies:
  google_sign_in: ^6.2.1                                    # TO REMOVE
  googleapis: ^13.1.0                                       # KEEP
  googleapis_auth: ^1.4.1                                   # KEEP
  extension_google_sign_in_as_googleapis_auth: ^2.0.9       # TO REMOVE
```

#### Key Files to Modify
1. **lib/google_calendar_service.dart** - Main authentication service (629 lines)
2. **pubspec.yaml** - Dependencies
3. **android/app/build.gradle.kts** - Android configuration
4. **Google Cloud Console** - OAuth client configuration (may need changes)

#### Current Authentication Flow
```
GoogleSignIn → Authentication → Access Token → Calendar API
```

### Target Architecture

#### New Dependencies
```yaml
dependencies:
  credential_manager: ^2.0.3                               # NEW
  googleapis: ^13.1.0                                      # KEEP
  googleapis_auth: ^1.4.1                                  # KEEP
```

#### New Authentication Flow
```
CredentialManager → Google Credential → Access Token → Calendar API
```

### Migration Steps

#### Phase 1: Research & Setup (1-2 hours)
1. Study Credential Manager API documentation
2. Understand authentication flow differences
3. Plan code structure changes
4. Identify potential breaking changes

#### Phase 2: Dependencies & Configuration (30 minutes)
1. Update `pubspec.yaml` dependencies
2. Update `android/app/build.gradle.kts` if needed
3. Verify Google Cloud Console OAuth client compatibility
4. Test dependency resolution

#### Phase 3: Core Implementation (4-6 hours)
1. **Backup current working code**
2. Rewrite `GoogleCalendarService` class:
   - Replace `GoogleSignIn` with `CredentialManager`
   - Update authentication methods
   - Modify token management
   - Update error handling
3. Update all authentication state management
4. Modify UI components that interact with auth service

#### Phase 4: Testing & Debugging (2-4 hours)
1. Test local development authentication
2. Test token refresh functionality
3. Test Google Calendar API integration
4. Test GitHub Actions build compatibility
5. Verify all authentication flows work correctly

### Key Implementation Considerations

#### Authentication Methods to Migrate
- `signIn()` - Interactive sign-in
- `signInSilently()` - Silent/automatic sign-in
- `signOut()` - Sign out functionality
- `isSignedIn()` - Authentication state check
- `getCurrentUser()` - Get current user info
- Token refresh and management

#### Error Handling Updates
- Different error types and codes
- Updated exception handling
- New authentication failure scenarios

#### State Management
- User authentication state
- Token expiration tracking
- Persistent login status

### Risk Assessment

#### Low Risk
- ✅ Dependencies are well-maintained
- ✅ Google's official recommendation
- ✅ Extensive documentation available

#### Medium Risk
- ⚠️ Learning curve for new API
- ⚠️ Potential UI/UX changes needed
- ⚠️ Testing required across different scenarios

#### Mitigation Strategies
- Keep backup of working code
- Implement in feature branch
- Thorough testing before deployment
- Rollback plan if issues arise

### Success Criteria

#### Must Have
- ✅ Local development authentication works
- ✅ GitHub Actions APK authentication works
- ✅ Google Calendar integration functional
- ✅ Token refresh works properly
- ✅ User state persistence works

#### Nice to Have
- ✅ Improved error messages
- ✅ Better authentication UX
- ✅ Future-proof architecture

### Current Working Configuration (Backup Reference)

#### OAuth Client (Google Cloud Console)
- **Type**: Android
- **Package Name**: `ie.qqrxi.spdrivercalendar`
- **SHA-1**: `30:EF:94:24:66:4C:28:C7:C8:59:01:3E:DC:BA:EF:21:B2:7F:FD:DF`

#### Web Client ID (for serverClientId)
- **Client ID**: `1051329330296-l7so8o8bfdm4h1g1hj9ql30dmuq1514e.apps.googleusercontent.com`

#### Current Scopes
```dart
scopes: [
  'email',
  'https://www.googleapis.com/auth/calendar',
]
```

### Next Steps for New Chat

1. **Start with Phase 1**: Research Credential Manager API
2. **Create feature branch**: `git checkout -b credential-manager-migration`
3. **Backup current code**: Ensure working version is preserved
4. **Begin implementation**: Start with dependency updates
5. **Test incrementally**: Verify each step works before proceeding

### Files to Reference in New Chat

1. **lib/google_calendar_service.dart** - Current implementation
2. **pubspec.yaml** - Current dependencies
3. **android/app/build.gradle.kts** - Android configuration
4. This context file for complete background

### Version Information
- **Current Version**: 2.8.25+1
- **Last Working Local Build**: Confirmed working with current setup
- **Last Failed GitHub APK**: v2.8.24 (confirmed same issue persists)

---

**Ready for migration! This context provides everything needed to start the Credential Manager implementation in a fresh chat session.** 