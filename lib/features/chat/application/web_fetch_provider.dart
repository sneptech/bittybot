import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/web_fetch_service.dart';

part 'web_fetch_provider.g.dart';

/// Provides the stateless [WebFetchService] used by chat web-search mode.
@riverpod
WebFetchService webFetchService(Ref ref) => WebFetchService();
