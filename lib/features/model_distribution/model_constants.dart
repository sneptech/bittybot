/// Hard-coded constants for the Tiny Aya Global Q3_K_S model.
///
/// All values are sourced from the official GitHub release URL:
/// https://github.com/sneptech/bittybot/releases/download/v0.1.0-q3ks/tiny-aya-global-q3_k_s.gguf
///
/// SHA-256 was verified 2026-02-19. Update [sha256Hash] and [fileSizeBytes]
/// if CohereLabs re-uploads the file with a new quantization.
abstract final class ModelConstants {
  /// Direct download URL from GitHub releases.
  static const String downloadUrl =
      'https://github.com/sneptech/bittybot/releases/download/v0.1.0-q3ks/'
      'tiny-aya-global-q3_k_s.gguf';

  /// Filename used locally and as the [background_downloader] task filename.
  static const String filename = 'tiny-aya-global-q3_k_s.gguf';

  /// Exact file size in bytes (~1.55 GB).
  /// Used to estimate download progress when Content-Length is unavailable.
  static const int fileSizeBytes = 1660984928;

  /// SHA-256 digest of the GGUF file as verified from GitHub release.
  /// Compared against the locally computed hash after download and on every
  /// subsequent launch before loading the model into memory.
  static const String sha256Hash =
      '381ef5cec4cab609f30914b6978af962354aadb1d8254829713815a198da9026';

  /// Subdirectory under [getApplicationSupportDirectory] where the model is stored.
  static const String modelSubdirectory = 'models';

  /// Minimum free disk space required before starting the download (MB).
  /// 1660 MB model + ~400 MB buffer for OS overhead and GGUF mmap.
  static const int requiredFreeSpaceMB = 2060;

  /// Devices with less than this much physical RAM (MB) are considered at risk
  /// of OOM when loading the model. A warning is shown but the user can proceed.
  static const int lowMemoryThresholdMB = 4096;

  /// Human-readable file size string shown in the download UI.
  static const String fileSizeDisplayGB = '~1.55 GB';

  /// Returns the absolute path to the models subdirectory within [appSupportPath].
  static String modelDirectory(String appSupportPath) =>
      '$appSupportPath/$modelSubdirectory';

  /// Returns the absolute path to the GGUF model file within [appSupportPath].
  static String modelFilePath(String appSupportPath) =>
      '${modelDirectory(appSupportPath)}/$filename';
}
