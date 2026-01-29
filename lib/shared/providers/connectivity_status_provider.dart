import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, isChecking }

final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final controller = StreamController<ConnectivityStatus>();

  // Set initial status
  controller.add(ConnectivityStatus.isChecking);

  final subscription = Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
    // result is now a List in newer versions of connectivity_plus
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      controller.add(ConnectivityStatus.isDisconnected);
    } else {
      controller.add(ConnectivityStatus.isConnected);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});
