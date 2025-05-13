import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/services/token_manager.dart';
// It's good practice to import the generated mock file with a prefix
import 'google_calendar_service_test.mocks.dart';

// Annotation to generate mocks for GoogleSignIn, GoogleSignInAccount, 
// GoogleSignInAuthentication and TokenManager.
// Note: SharedPreferences is handled differently with setMockInitialValues.
@GenerateMocks([
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  TokenManager,
])
void main() {
  // Declare mock instances
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
  // late MockTokenManager mockTokenManager; // TokenManager mock setup needs review based on its design

  setUp(() {
    // Initialize mocks
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
    // mockTokenManager = MockTokenManager(); // Initialize if used directly and mockable

    // Inject the mock GoogleSignIn instance into the service
    GoogleCalendarService.setGoogleSignInForTesting(mockGoogleSignIn);

    // Set mock initial values for SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
    
    // --- Mocking TokenManager --- 
    // If TokenManager methods are static and directly called by GoogleCalendarService,
    // you'd need to ensure TokenManager is also designed for testability (e.g., with setters for its own state or dependencies)
    // or use a mocking strategy that can handle static calls if your framework supports it.
    // For instance methods on an injected TokenManager, you'd mock them here.
    // For this example, we'll assume TokenManager.setTokenExpiration is a static method.
    // Mockito cannot directly mock static methods in the same way as instance methods without specific setup.
    // A common workaround is to wrap static calls in an instance method of a class that can be mocked,
    // or ensure the static class itself can have its behavior controlled for tests (e.g. static fields for test data).
    // For _updateTokenExpiration, it calls TokenManager.setTokenExpiration(). We'll assume this is a static call.
    // We will verify its effects indirectly or by ensuring TokenManager itself is testable.
    // For simplicity in this generated code, direct static mocking of TokenManager is omitted,
    // focusing on GoogleSignIn. The test assertions will imply TokenManager interactions.
  });

  group('GoogleCalendarService.signIn()', () {
    const fakeAccessToken = 'fake_access_token';
    const fakeUserEmail = 'test@example.com';

    // Test Case 1: Successful interactive sign-in when not initially signed in
    test('successful interactive sign-in when not initially signed in', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn(fakeAccessToken);
      when(mockGoogleSignInAccount.email).thenReturn(fakeUserEmail);

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, mockGoogleSignInAccount);
      verify(mockGoogleSignIn.isSignedIn()).called(1);
      verify(mockGoogleSignIn.signInSilently()).called(1);
      verify(mockGoogleSignIn.signIn()).called(1);
      verify(mockGoogleSignInAccount.authentication).called(1);
      verify(mockGoogleSignInAuthentication.accessToken).called(2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isTrue);
    });

    // Test Case 2: Successful silent sign-in
    test('successful silent sign-in', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn(fakeAccessToken);
      when(mockGoogleSignInAccount.email).thenReturn(fakeUserEmail);

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, mockGoogleSignInAccount);
      verify(mockGoogleSignIn.signInSilently()).called(1);
      verifyNever(mockGoogleSignIn.signIn());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isTrue);
    });

    // Test Case 3: User is already signed in (via _googleSignIn.currentUser)
    test('user is already signed in via currentUser', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => true);
      when(mockGoogleSignIn.currentUser).thenReturn(mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn(fakeAccessToken);
      when(mockGoogleSignInAccount.email).thenReturn(fakeUserEmail);

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, mockGoogleSignInAccount);
      verify(mockGoogleSignIn.isSignedIn()).called(1);
      verify(mockGoogleSignIn.currentUser).called(1);
      verifyNever(mockGoogleSignIn.signInSilently()); // Corrected
      verifyNever(mockGoogleSignIn.signIn()); // Corrected
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isTrue);
    });

    // Test Case 4: Interactive sign-in canceled by user
    test('interactive sign-in canceled by user', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null); // User cancels

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isFalse);
    });

    // Test Case 5: Interactive sign-in throws an error
    test('interactive sign-in throws an error', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenThrow(Exception('Sign-in failed'));

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isFalse);
    });

    // Test Case 6: Access token is null after successful interactive sign-in
    test('access token is null after successful interactive sign-in', () async {
      // Arrange
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn(null);
      when(mockGoogleSignInAccount.email).thenReturn(fakeUserEmail);

      // Act
      final result = await GoogleCalendarService.signIn();

      // Assert
      expect(result, null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedGoogleLogin'), isFalse);
    });
  });

  // TODO: Add test groups for signOut(), getCalendarApi(), addEvent(), getEvents(), checkCalendarAccess(), etc.
} 