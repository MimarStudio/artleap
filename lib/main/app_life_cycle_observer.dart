import 'package:Artleap.ai/shared/route_export.dart';


class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _registerDeviceTokenOnResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _registerDeviceTokenOnResume() async {
    if (UserData.ins.userId != null) {
      await AppInitialization.registerDeviceTokenOnStartup(ref);
    }
  }
}