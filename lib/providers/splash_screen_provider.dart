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
  readyToNavigate,
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
      bool firebaseInitialized = await _initializeFirebaseWithRetry();

      if (firebaseInitialized) {
        await Future.delayed(const Duration(milliseconds: 500));
        state = SplashState.readyToNavigate;
      } else {
        state = SplashState.firebaseError;
      }
    } catch (e) {
      state = SplashState.firebaseError;
      print(e.toString());
    }
  }

  Future<bool> _initializeFirebaseWithRetry() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        state = SplashState.initializing;
        await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firebase initialization timeout'),
        );
        return true;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          return false;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    return false;
  }

  void retryInitialization() {
    state = SplashState.initializing;
    initializeApp();
  }
}

final splashStateProvider = StateNotifierProvider<SplashStateNotifier, SplashState>(
      (ref) => SplashStateNotifier(),
);