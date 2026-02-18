/// Hard-coded constants for the Tiny Aya Global Q4_K_M model.
///
/// All values are sourced from the official HuggingFace repository:
/// https://huggingface.co/CohereLabs/tiny-aya-global-GGUF
///
/// SHA-256 was verified 2026-02-19. Update [sha256Hash] and [fileSizeBytes]
/// if CohereLabs re-uploads the file with a new quantization.
abstract final class ModelConstants {
  /// Direct download URL from HuggingFace CDN.
  static const String downloadUrl =
      'https://huggingface.co/CohereLabs/tiny-aya-global-GGUF/resolve/main/'
      'tiny-aya-global-q4_k_m.gguf?download=true';

  /// Filename used locally and as the [background_downloader] task filename.
  static const String filename = 'tiny-aya-global-q4_k_m.gguf';

  /// Exact file size in bytes (~2.14 GB).
  /// Used to estimate download progress when Content-Length is unavailable.
  static const int fileSizeBytes = 2299396096;

  /// SHA-256 digest of the GGUF file as verified from HuggingFace.
  /// Compared against the locally computed hash after download and on every
  /// subsequent launch before loading the model into memory.
  static const String sha256Hash =
      'd01d995272af305b2b843efcff8a10cf9869cf53e764cb72b0e91b777484570a';

  /// Subdirectory under [getApplicationSupportDirectory] where the model is stored.
  static const String modelSubdirectory = 'models';

  /// Minimum free disk space required before starting the download (MB).
  /// 2560 MB = 2.14 GB model + ~400 MB buffer for OS overhead and GGUF mmap.
  static const int requiredFreeSpaceMB = 2560;

  /// Devices with less than this much physical RAM (MB) are considered at risk
  /// of OOM when loading the model. A warning is shown but the user can proceed.
  static const int lowMemoryThresholdMB = 4096;

  /// Human-readable file size string shown in the download UI.
  static const String fileSizeDisplayGB = '~2.14 GB';

  /// Returns the absolute path to the models subdirectory within [appSupportPath].
  static String modelDirectory(String appSupportPath) =>
      '$appSupportPath/$modelSubdirectory';

  /// Returns the absolute path to the GGUF model file within [appSupportPath].
  static String modelFilePath(String appSupportPath) =>
      '${modelDirectory(appSupportPath)}/$filename';
}
