import 'dart:io';

import 'package:bittybot/features/model_distribution/model_constants.dart';
import 'package:bittybot/features/model_distribution/model_distribution_notifier.dart';
import 'package:bittybot/features/model_distribution/model_distribution_state.dart';
import 'package:bittybot/features/model_distribution/providers.dart';
import 'package:bittybot/features/model_distribution/storage_preflight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  Future<File> createModelFile({required int sizeBytes}) async {
    final modelPath = ModelConstants.modelFilePath(tempDir.path);
    final modelFile = File(modelPath);
    await modelFile.parent.create(recursive: true);
    final bytes = List<int>.generate(sizeBytes, (index) => index % 251);
    await modelFile.writeAsBytes(bytes, flush: true);
    return modelFile;
  }

  ProviderContainer createContainer({
    required Future<bool> Function(String) verifyModelFileFn,
    Future<StorageCheckResult> Function(String)? storageChecker,
    Future<ConnectionType> Function()? connectionChecker,
  }) {
    return ProviderContainer(
      overrides: [
        modelDistributionProvider.overrideWith(
          () => ModelDistributionNotifier(
            appSupportDirectoryProvider: () async => tempDir,
            verifyModelFileFn: verifyModelFileFn,
            sharedPreferencesProvider: SharedPreferences.getInstance,
            storageChecker:
                storageChecker ?? (_) async => const StorageSufficient(),
            connectionChecker:
                connectionChecker ?? () async => ConnectionType.none,
            lowMemoryChecker: () async => false,
          ),
        ),
      ],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp('sha256_skip_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'verified flag + matching size skips SHA-256 and proceeds to load',
    () async {
      final modelFile = await createModelFile(sizeBytes: 64);
      final size = await modelFile.length();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('model_verified', true);
      await prefs.setInt('model_verified_size', size);

      var verifyCalls = 0;
      final container = createContainer(
        verifyModelFileFn: (_) async {
          verifyCalls++;
          return true;
        },
      );
      addTearDown(container.dispose);

      final notifier = container.read(modelDistributionProvider.notifier);
      await notifier.initialize();

      expect(verifyCalls, 0);
      expect(container.read(modelDistributionProvider), isA<ModelReadyState>());
    },
  );

  test('verified flag + size mismatch runs SHA-256', () async {
    final modelFile = await createModelFile(sizeBytes: 64);
    final actualSize = await modelFile.length();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('model_verified', true);
    await prefs.setInt('model_verified_size', actualSize + 1);

    var verifyCalls = 0;
    final container = createContainer(
      verifyModelFileFn: (_) async {
        verifyCalls++;
        return true;
      },
    );
    addTearDown(container.dispose);

    final notifier = container.read(modelDistributionProvider.notifier);
    await notifier.initialize();

    expect(verifyCalls, 1);
    expect(container.read(modelDistributionProvider), isA<ModelReadyState>());
  });

  test('no verified flag runs SHA-256', () async {
    await createModelFile(sizeBytes: 64);

    var verifyCalls = 0;
    final container = createContainer(
      verifyModelFileFn: (_) async {
        verifyCalls++;
        return true;
      },
    );
    addTearDown(container.dispose);

    final notifier = container.read(modelDistributionProvider.notifier);
    await notifier.initialize();

    expect(verifyCalls, 1);
    expect(container.read(modelDistributionProvider), isA<ModelReadyState>());
  });

  test(
    'successful verification persists verified flag and file size',
    () async {
      final modelFile = await createModelFile(sizeBytes: 96);
      final expectedSize = await modelFile.length();

      final container = createContainer(verifyModelFileFn: (_) async => true);
      addTearDown(container.dispose);

      final notifier = container.read(modelDistributionProvider.notifier);
      await notifier.initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('model_verified'), isTrue);
      expect(prefs.getInt('model_verified_size'), expectedSize);
    },
  );

  test('failed verification clears verified flag and size', () async {
    final modelFile = await createModelFile(sizeBytes: 96);
    final modelSize = await modelFile.length();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('model_verified', true);
    await prefs.setInt('model_verified_size', modelSize + 1);

    final container = createContainer(verifyModelFileFn: (_) async => false);
    addTearDown(container.dispose);

    final notifier = container.read(modelDistributionProvider.notifier);
    await notifier.initialize();

    final updatedPrefs = await SharedPreferences.getInstance();
    expect(updatedPrefs.getBool('model_verified'), isNull);
    expect(updatedPrefs.getInt('model_verified_size'), isNull);
    expect(await modelFile.exists(), isFalse);
  });
}
