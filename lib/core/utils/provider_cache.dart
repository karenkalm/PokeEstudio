import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheForExtension on Ref {
  /// Mantiene vivo un provider `autoDispose` durante [duration] después de que
  /// nadie lo escuche. Así, volver a una ficha recién vista es instantáneo,
  /// pero la memoria se libera si el usuario ya no regresa.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });
    onResume(() {
      timer?.cancel();
      timer = null;
    });
    onDispose(() => timer?.cancel());
  }
}
