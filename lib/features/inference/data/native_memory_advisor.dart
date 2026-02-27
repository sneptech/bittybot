import 'dart:ffi';

import 'package:ffi/ffi.dart';

// POSIX_FADV_WILLNEED = 3 on Linux/Android.
const int _posixFadvWillneed = 3;

// O_RDONLY = 0.
const int _oRdonly = 0;

// int open(const char *pathname, int flags);
typedef OpenNative = Int32 Function(Pointer<Utf8> path, Int32 flags);
typedef OpenDart = int Function(Pointer<Utf8> path, int flags);

// int close(int fd);
typedef CloseNative = Int32 Function(Int32 fd);
typedef CloseDart = int Function(int fd);

// int posix_fadvise(int fd, off_t offset, off_t len, int advice);
typedef PosixFadviseNative =
    Int32 Function(Int32 fd, Int64 offset, Int64 len, Int32 advice);
typedef PosixFadviseDart =
    int Function(int fd, int offset, int len, int advice);

/// Opens [path] read-only via libc and calls POSIX_FADV_WILLNEED.
///
/// Returns the native fd (>= 0) on success so the caller can keep it open
/// for the model lifetime. Returns -1 on failure.
int adviseWillNeed(String path, int fileLength) {
  try {
    final dylib = DynamicLibrary.open('libc.so');

    final open = dylib.lookupFunction<OpenNative, OpenDart>('open');
    final posixFadvise = dylib
        .lookupFunction<PosixFadviseNative, PosixFadviseDart>('posix_fadvise');

    final pathPtr = path.toNativeUtf8();
    final fd = open(pathPtr, _oRdonly);
    calloc.free(pathPtr);

    if (fd < 0) {
      return -1;
    }

    posixFadvise(fd, 0, fileLength, _posixFadvWillneed);
    return fd;
  } catch (_) {
    return -1;
  }
}

/// Best-effort native file descriptor cleanup.
void closeNativeFd(int fd) {
  if (fd < 0) {
    return;
  }

  try {
    final dylib = DynamicLibrary.open('libc.so');
    final close = dylib.lookupFunction<CloseNative, CloseDart>('close');
    close(fd);
  } catch (_) {
    // Ignore cleanup failures.
  }
}
