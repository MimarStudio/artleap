import 'package:firebase_auth/firebase_auth.dart';
import 'package:Artleap.ai/domain/base_repo/base_repo.dart';
import '../domain/api_services/api_response.dart';
import '../domain/auth_services/auth_services.dart';
import '../shared/auth_exception_handler/auth_exception_handler.dart';
import 'package:Artleap.ai/shared/route_export.dart';


enum ObsecureText { loginPassword, signupPassword, confirmPassword }

enum LoginMethod { email, signup, google, facebook, apple, forgotPassword }

final authprovider =
ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider(ref));

class AuthProvider extends ChangeNotifier with BaseRepo {
  final AuthServices _authServices = AuthServices();
  final TextEditingController _userNameController = TextEditingController();
  TextEditingController get userNameController => _userNameController;
  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;
  final TextEditingController _passwordController = TextEditingController();
  TextEditingController get passwordController => _passwordController;
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  bool _loginPasswordHideShow = true;
  bool get loginPasswordHideShow => _loginPasswordHideShow;
  bool _signupPasswordHideShow = true;
  bool get signupPasswordHideShow => _signupPasswordHideShow;
  bool _confirmPasswordHideShow = true;
  bool get confirmPasswordHideShow => _confirmPasswordHideShow;
  final Ref reference;
  AuthProvider(this.reference);

  final Map<LoginMethod, bool> _loaders = {
    LoginMethod.email: false,
    LoginMethod.google: false,
    LoginMethod.facebook: false,
    LoginMethod.apple: false,
    LoginMethod.signup: false,
    LoginMethod.forgotPassword: false,
  };
  bool isLoading(LoginMethod loginMethod) => _loaders[loginMethod] ?? false;

  void startLoading(LoginMethod loginMethod) {
    _loaders[loginMethod] = true;
    notifyListeners();
  }

  void stopLoading(LoginMethod loginMethod) {
    _loaders[loginMethod] = false;
    notifyListeners();
  }

  UserAuthResult? _authError;
  UserAuthResult? get authError => _authError;

  void clearError() {
    _authError = null;
    notifyListeners();
  }

  void _setError(String message, AuthResultStatus status) {
    _authError = UserAuthResult(
      authResultState: status,
      message: message,
    );
    notifyListeners();
  }

  Future<void> storeFirebaseAuthToken({bool forceRefresh = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      final idToken = await user.getIdToken(forceRefresh);
      if (idToken != null) {
        AppData.instance.setToken(idToken);
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        final status = AuthExceptionHandler.handleException(e);
        final message = AuthExceptionHandler.generateExceptionMessage(status);
        _setError(message, AuthResultStatus.error);
      }
    }
  }

  Future<String?> ensureValidFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigation.pushNamed(LoginScreen.routeName);
        });
        return null;
      }

      await user.reload();
      final idToken = await user.getIdToken(true);
      if (idToken != null) {
        AppData.instance.setToken(idToken);
        return idToken;
      }
      return null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        final status = AuthExceptionHandler.handleException(e);
        final message = AuthExceptionHandler.generateExceptionMessage(status);
        _setError(message, AuthResultStatus.error);

        if (status == AuthResultStatus.userNotFound ||
            status == AuthResultStatus.undefined ||
            e.code == 'invalid-user-token') {
          await FirebaseAuth.instance.signOut();
          AppData.instance.clearToken();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigation.pushNamedAndRemoveUntil(LoginScreen.routeName);
          });
        }
      } else {
        _setError('Failed to refresh token. Please try again.', AuthResultStatus.error);
      }
      return null;
    }
  }

  Future<void> signUpWithEmail() async {
    try {
      if (userNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        _setError("Please fill all the fields", AuthResultStatus.error);
        return;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _setError("Passwords are not matching", AuthResultStatus.error);
        return;
      }

      startLoading(LoginMethod.signup);
      UserAuthResult? user = await _authServices.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (user.authResultState == AuthResultStatus.error) {
        _setError(user.message!, user.authResultState);
      } else if (isNotNull(user)) {
        clearError();
        await userSignup(
          userNameController.text,
          emailController.text,
          passwordController.text,
        );
        AppLocal.ins.setUserData(Hivekey.userName, _userNameController.text);
        AppLocal.ins.setUserData(Hivekey.userEmail, _emailController.text);
        Navigation.pushNamedAndRemoveUntil(LoginScreen.routeName);
      }
    } catch (e) {
      final errorMessage = e is FirebaseAuthException
          ? AuthExceptionHandler.generateExceptionMessage(
          AuthExceptionHandler.handleException(e))
          : 'An unexpected error occurred during sign-up.';
      _setError(errorMessage, AuthResultStatus.error);
    } finally {
      stopLoading(LoginMethod.signup);
    }
  }

  Future<void> signInWithEmail() async {
    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        _setError("Please fill all the fields", AuthResultStatus.error);
        stopLoading(LoginMethod.email);
        return;
      }

      startLoading(LoginMethod.email);
      UserAuthResult user = await _authServices.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (user.authResultState == AuthResultStatus.error) {
        _setError(user.message!, user.authResultState);
      } else if (isNotNull(user)) {
        await userLogin(emailController.text, passwordController.text);
        await storeFirebaseAuthToken();
        clearControllers();
      }
    } catch (e) {
      final errorMessage = e is FirebaseAuthException
          ? AuthExceptionHandler.generateExceptionMessage(
          AuthExceptionHandler.handleException(e))
          : 'An unexpected error occurred during sign-in.';
      _setError(errorMessage, AuthResultStatus.error);
    } finally {
      stopLoading(LoginMethod.email);
    }
  }

  Future<void> forgotPassword(BuildContext context) async {
    try {
      startLoading(LoginMethod.forgotPassword);
      if (emailController.text.isEmpty) {
        _setError("Please enter your email address", AuthResultStatus.error);
        return;
      }

      Map<String, String> body = {
        "email": emailController.text,
      };
      ApiResponse userRes = await authRepo.forgotPassword(body: body);
      if (userRes.status == Status.completed &&
          (userRes.data == 'Success' || userRes.data == 'Sucesss')) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else {
        _setError(userRes.message ?? 'Something went wrong. Please try again.', AuthResultStatus.error);
      }
    } catch (e) {
      final errorMessage = e is FirebaseAuthException
          ? AuthExceptionHandler.generateExceptionMessage(
          AuthExceptionHandler.handleException(e))
          : 'Failed to send password reset email.';
      _setError(errorMessage, AuthResultStatus.error);
    } finally {
      stopLoading(LoginMethod.forgotPassword);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      startLoading(LoginMethod.google);
      await _authServices.signOutGoogle();

      AuthResult? userCred = await _authServices.signInWithGoogle();
      if (userCred != null &&
          userCred.userCredential != null &&
          userCred.userCredential!.user != null) {
        final user = userCred.userCredential!.user!;

        await user.reload();
        final token = await ensureValidFirebaseToken();
        if (token == null || token.isEmpty) {
          throw FirebaseAuthException(
              code: 'token-missing',
              message: 'Unable to fetch ID token after Google sign-in.');
        }

        await googleLogin(
          user.displayName ?? 'User',
          user.email ?? '',
          user.uid,
          user.photoURL ?? '',
        );
      } else {
        _setError('Google sign-in failed. Please try again.', AuthResultStatus.error);
      }
    } catch (e) {
      final errorMessage = e is FirebaseAuthException
          ? AuthExceptionHandler.generateExceptionMessage(
          AuthExceptionHandler.handleException(e))
          : 'An unexpected error occurred during Google sign-in.';
      _setError(errorMessage, AuthResultStatus.error);
    } finally {
      stopLoading(LoginMethod.google);
    }
  }

  Future<void> signInWithApple() async {
    try {
      startLoading(LoginMethod.apple);
      UserCredential? userCred = await _authServices.signInWithApple();
      if (isNotNull(userCred)) {
        final user = userCred!.user!;
        await storeFirebaseAuthToken();
        await appleLogin(
          user.displayName ?? 'User',
          user.email ?? '',
          user.uid,
          user.photoURL ?? '',
        );
      } else {
        _setError('Apple sign-in failed. Please try again.', AuthResultStatus.error);
      }
    } catch (e) {
      final errorMessage = e is FirebaseAuthException
          ? AuthExceptionHandler.generateExceptionMessage(
          AuthExceptionHandler.handleException(e))
          : 'An unexpected error occurred during Apple sign-in.';
      _setError(errorMessage, AuthResultStatus.error);
    } finally {
      stopLoading(LoginMethod.apple);
    }
  }

  Future<void> signOut() async {
    try {
      await _authServices.signOutGoogle();
      await FirebaseAuth.instance.signOut();
      AppData.instance.clearToken();
      await AppLocal.ins.clearUserData();
      clearControllers();
      clearError();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigation.pushNamedAndRemoveUntil(LoginScreen.routeName);
      });
    } catch (e) {
      _setError('Failed to sign out. Please try again.', AuthResultStatus.error);
    }
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    userNameController.clear();
    notifyListeners();
  }

  void obsecureTextFtn(ObsecureText field) {
    switch (field) {
      case ObsecureText.loginPassword:
        _loginPasswordHideShow = !_loginPasswordHideShow;
        break;
      case ObsecureText.signupPassword:
        _signupPasswordHideShow = !_signupPasswordHideShow;
        break;
      case ObsecureText.confirmPassword:
        _confirmPasswordHideShow = !_confirmPasswordHideShow;
        break;
    }
    notifyListeners();
  }

  Future<void> userLogin(String email, String password) async {
    try {
      Map<String, String> body = {
        "email": email,
        "password": password,
      };
      ApiResponse userRes = await authRepo.login(body: body);
      if (userRes.status == Status.completed) {
        final userId = userRes.data["user"]['userId'];
        final userName = userRes.data["user"]['username'];
        final userEmail = userRes.data["user"]['email'];

        reference.read(userProfileProvider.notifier).getUserProfileData(userId);
        AppLocal.ins.setUserData(Hivekey.userId, userId);
        AppLocal.ins.setUserData(Hivekey.userName, userName);
        AppLocal.ins.setUserData(Hivekey.userEmail, userEmail);

        await AppInitialization.registerUserDeviceToken(reference);

        await _navigateAfterSuccessfulLogin();
      } else {
        _setError(userRes.message ?? 'Failed to log in to backend.', AuthResultStatus.error);
      }
    } catch (e) {
      _setError('Failed to connect to backend. Please try again.', AuthResultStatus.error);
    }
  }

  Future<void> userSignup(
      String userName, String email, String password) async {
    try {
      Map<String, String> body = {
        "username": userName,
        "email": email,
        "password": password,
      };
      ApiResponse userRes = await authRepo.signup(body: body);
      if (userRes.status != Status.completed) {
        _setError(userRes.message ?? 'Failed to sign up to backend.', AuthResultStatus.error);
      }
    } catch (e) {
      _setError('Failed to connect to backend. Please try again.', AuthResultStatus.error);
    }
  }

  Future<void> googleLogin(
      String userName, String email, String googleId, String profilePic) async {
    try {
      Map<String, String> body = {
        "username": userName,
        "email": email,
        "googleId": googleId,
        "profilePic": profilePic,
      };
      ApiResponse userRes = await authRepo.googleLogin(body: body);
      if (userRes.status == Status.completed) {
        final raw = userRes.data;
        final Map user = (raw is Map && raw['user'] is Map)
            ? raw['user'] as Map
            : (raw as Map);

        final String userId = (user['userId'] ?? user['id'] ?? '').toString().trim();
        final String username = (user['username'] ?? userName).toString();
        final String userEmail = (user['email'] ?? email).toString();
        final String userPic = (user['profilePic'] ?? profilePic ?? '').toString();

        if (userId.isEmpty) {
          throw Exception('userId missing in backend response');
        }

        AppData.instance.setUserId(userId);
        reference.read(userProfileProvider.notifier).getUserProfileData(userId);

        AppLocal.ins.setUserData(Hivekey.userId, userId);
        AppLocal.ins.setUserData(Hivekey.userName, username);
        AppLocal.ins.setUserData(Hivekey.userEmail, userEmail);
        if (userPic.isNotEmpty) {
          AppLocal.ins.setUserData(Hivekey.userProfielPic, userPic);
        }

        await AppInitialization.registerUserDeviceToken(reference);

        await _navigateAfterSuccessfulLogin();
      } else {
        _setError(userRes.message ?? 'Failed to log in with Google.', AuthResultStatus.error);
      }
    } catch (e) {
      _setError('Failed to connect to backend. Please try again.', AuthResultStatus.error);
    }
  }

  Future<void> appleLogin(
      String userName, String email, String appleId, String profilePic) async {
    try {
      Map<String, String> body = {
        "username": userName,
        "email": email,
        "appleId": appleId,
        "profilePic": profilePic,
      };
      ApiResponse userRes = await authRepo.appleLogin(body: body);
      if (userRes.status == Status.completed) {
        final userId = userRes.data["user"]['userId'];
        final username = userRes.data["user"]['username'];
        final userEmail = userRes.data["user"]['email'];
        final userPic = userRes.data["user"]['profilePic'] ?? profilePic;

        reference.read(userProfileProvider.notifier).getUserProfileData(userId);
        AppLocal.ins.setUserData(Hivekey.userId, userId);
        AppLocal.ins.setUserData(Hivekey.userName, username);
        AppLocal.ins.setUserData(Hivekey.userEmail, userEmail);
        if (userPic.isNotEmpty) {
          AppLocal.ins.setUserData(Hivekey.userProfielPic, userPic);
        }

        await AppInitialization.registerUserDeviceToken(reference);

        await _navigateAfterSuccessfulLogin();
      } else {
        _setError(userRes.message ?? 'Failed to log in with Apple.', AuthResultStatus.error);
      }
    } catch (e) {
      _setError('Failed to connect to backend. Please try again.', AuthResultStatus.error);
    }
  }

  Future<void> _navigateAfterSuccessfulLogin() async {
    await Future.delayed(Duration(milliseconds: 500));

    try {
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        final userId = AppLocal.ins.getUSerData(Hivekey.userId) ?? "";
        final userName = AppLocal.ins.getUSerData(Hivekey.userName) ?? "";
        final userEmail = AppLocal.ins.getUSerData(Hivekey.userEmail) ?? "";
        final userProfilePicture = AppLocal.ins.getUSerData(Hivekey.userProfielPic) ?? "";

        await ArtleapNavigationManager.navigateBasedOnUserStatusWithRef(
          context: navigatorContext,
          ref: reference,
          userId: userId,
          userName: userName,
          userProfilePicture: userProfilePicture,
          userEmail: userEmail,
          hasSeenTutorial: await ArtleapNavigationManager.getTutorialStatusWithRef(reference),
        );
      } else {
        Navigation.pushNamedAndRemoveUntil(AcceptPrivacyPolicyScreen.routeName);
      }
    } catch (e) {
      print('Navigation error: $e');
      Navigation.pushNamedAndRemoveUntil(AcceptPrivacyPolicyScreen.routeName);
    }
  }

  Future<void> ensureDeviceTokenRegistration() async {
    try {
      final userId = AppLocal.ins.getUSerData(Hivekey.userId);
      if (userId != null && userId.isNotEmpty) {
        await AppInitialization.registerUserDeviceToken(reference);
      }
    } catch (e) {
      print('Error ensuring device token registration: $e');
    }
  }
}