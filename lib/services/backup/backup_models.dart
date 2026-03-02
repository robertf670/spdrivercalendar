/// Platform-agnostic model for backup entries.
/// Used by both IO and Web backup implementations.
class BackupEntry {
  final String path;
  final DateTime modified;
  final int size;

  const BackupEntry({
    required this.path,
    required this.modified,
    required this.size,
  });
}
