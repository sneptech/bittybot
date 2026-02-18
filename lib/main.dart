import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {
  // CRITICAL: disable runtime font fetching — app is offline-first.
  // Fonts are bundled in assets/google_fonts/ and must never be fetched from
  // the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BittyBotApp()));
}
