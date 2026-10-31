import 'package:local_auth/local_auth.dart';

enum AuthResult {
  success,

  /// Wrong, cancelled, locked out for a while, or no prompt could be shown.
  failed,

  /// The phone has no screen lock to ask with. The app lock must not trap
  /// anyone behind a prompt that can never be answered.
  unavailable,
}

/// The phone's own fingerprint, face or screen-lock prompt. Behind an interface
/// so tests never touch the real thing.
abstract class DeviceAuth {
  /// Whether the phone has a screen lock (or biometrics) to ask with.
  Future<bool> isAvailable();

  Future<AuthResult> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(localizedReason: reason);
      return ok ? AuthResult.success : AuthResult.failed;
    } on LocalAuthException catch (e) {
      // A lockout after wrong tries is the phone's to enforce; we just stay locked.
      return e.code == LocalAuthExceptionCode.noCredentialsSet
          ? AuthResult.unavailable
          : AuthResult.failed;
    } on Object {
      return AuthResult.failed;
    }
  }
}
