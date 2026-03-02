/// PWA Work Access Code configuration (Web only).
///
/// Set [workAccessCodeHash] to the SHA-256 hash of your desired password.
/// Generate with: echo -n "yourpassword" | sha256sum (Linux/Mac)
/// Or in Dart: sha256.convert(utf8.encode('yourpassword')).toString()
///
/// For production build: --dart-define=WORK_ACCESS_HASH=your_sha256_hash
/// For GitHub Actions/Vercel: add WORK_ACCESS_HASH to dart-define in deploy workflow.
const String workAccessCodeHash = String.fromEnvironment(
  'WORK_ACCESS_HASH',
  defaultValue: 'ed823ec32c5d4e9ca9dd968bb0fe9366b7d904ce0cae615308ddd5b89f0e6a3a', // SHA-256 of "" - MUST change for production!
);
