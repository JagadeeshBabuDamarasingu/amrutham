import 'package:amrutham/lock/device_auth.dart';

/// A phone prompt that answers from a script: each call takes the next result
/// (the last one repeats), and every call is counted.
class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth({this.available = true, List<AuthResult>? results})
    : _results = results ?? [AuthResult.success];

  bool available;
  final List<AuthResult> _results;
  int calls = 0;
  String? lastReason;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AuthResult> authenticate(String reason) async {
    lastReason = reason;
    final i = calls < _results.length ? calls : _results.length - 1;
    calls++;
    return _results[i];
  }
}

/// A clock the test moves by hand.
class FakeClock {
  Duration now = Duration.zero;
  Duration call() => now;
  void advance(Duration d) => now += d;
}
