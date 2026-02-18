import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:system_info_plus/system_info_plus.dart';

import 'model_constants.dart';

// ─── Connection type ─────────────────────────────────────────────────────────

/// The type of network connection detected on the device.
enum ConnectionType {
  /// Connected via Wi-Fi or Ethernet — safe to start the 2.14 GB download.
  wifi,

  /// Connected via cellular — show the user a warning with the file size
  /// before proceeding.
  cellular,

  /// No network connection detected.
  none,
}

/// Detects the current network connection type using [connectivity_plus].
///
/// Returns [ConnectionType.wifi] for both Wi-Fi and Ethernet connections.
/// Returns [ConnectionType.cellular] if mobile data is the active connection.
/// Returns [ConnectionType.none] if no connection is available.
///
/// Note: A [ConnectionType.wifi] result indicates the device is associated with
/// a Wi-Fi network but does NOT guarantee internet access (captive portals may
/// block traffic). A failed download will hit the retry path — this is
/// acceptable behaviour.
Future<ConnectionType> checkConnectionType() async {
  final results = await Connectivity().checkConnectivity();
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return ConnectionType.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return ConnectionType.cellular;
  }
  return ConnectionType.none;
}

// ─── Storage check ───────────────────────────────────────────────────────────

/// Result of a storage pre-flight check.
sealed class StorageCheckResult {
  const StorageCheckResult();
}

/// Sufficient disk space is available to proceed with the download.
final class StorageSufficient extends StorageCheckResult {
  const StorageSufficient();
}

/// Insufficient disk space — the download cannot proceed.
///
/// Both values are in MB and are used to construct the error message shown
/// to the user (e.g. "Need 2.5 GB, you have 1.2 GB free").
final class StorageInsufficient extends StorageCheckResult {
  const StorageInsufficient({
    required this.neededMB,
    required this.availableMB,
  });

  /// How many MB are required (model + buffer).
  final int neededMB;

  /// How many MB are currently free on the device.
  final int availableMB;
}

/// Checks whether the device has enough free disk space to download and store
/// the model at [targetPath].
///
/// Compares available free space against [ModelConstants.requiredFreeSpaceMB].
/// Returns [StorageSufficient] if there is enough space, [StorageInsufficient]
/// with the exact deficit otherwise.
Future<StorageCheckResult> checkStorageSpace(String targetPath) async {
  final diskSpacePlus = DiskSpacePlus();
  final freeMB =
      (await diskSpacePlus.getFreeDiskSpaceForPath(targetPath)) ?? 0.0;
  final freeMBInt = freeMB.toInt();

  if (freeMBInt >= ModelConstants.requiredFreeSpaceMB) {
    return const StorageSufficient();
  }
  return StorageInsufficient(
    neededMB: ModelConstants.requiredFreeSpaceMB,
    availableMB: freeMBInt,
  );
}

// ─── RAM check ───────────────────────────────────────────────────────────────

/// Returns `true` if the device is likely to struggle loading the 2.14 GB
/// Q4_K_M model into memory.
///
/// Devices with less than [ModelConstants.lowMemoryThresholdMB] of physical RAM
/// are considered at risk of OOM during model load. The threshold is 4096 MB
/// (4 GB), as Q4_K_M typically needs 2–3 GB of addressable memory at peak.
///
/// Defaults to `false` (assumes sufficient memory) if the platform call fails,
/// to avoid blocking users on devices where RAM info is unavailable.
Future<bool> isLowMemoryDevice() async {
  try {
    final memoryMB = await SystemInfoPlus.physicalMemory;
    return (memoryMB ?? ModelConstants.lowMemoryThresholdMB + 1) <
        ModelConstants.lowMemoryThresholdMB;
  } catch (_) {
    // If we can't determine RAM, assume the device is sufficient.
    return false;
  }
}
