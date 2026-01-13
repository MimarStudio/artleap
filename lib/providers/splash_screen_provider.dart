import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplashState {
  initializing,
  checkingConnection,
  connected,
  noInternet,
  firebaseError,
}

class SplashStateNotifier extends StateNotifier<SplashState> {
  SplashStateNotifier() : super(SplashState.initializing);

  Future<void> initializeApp() async {
    try {
      state = SplashState.checkingConnection;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        state = SplashState.noInternet;
        return;
      }

      state = SplashState.connected;

      final firebaseOk = await _initializeFirebaseWithRetry();
      if (!firebaseOk) {
        state = SplashState.firebaseError;
      }
    } catch (_) {
      state = SplashState.firebaseError;
    }
  }

  Future<bool> _initializeFirebaseWithRetry() async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 10));
        return true;
      } catch (_) {
        if (attempt == maxAttempts) return false;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return false;
  }

  void retryInitialization() {
    state = SplashState.initializing;
    initializeApp();
  }
}

final splashStateProvider =
StateNotifierProvider<SplashStateNotifier, SplashState>(
      (ref) => SplashStateNotifier(),
);
