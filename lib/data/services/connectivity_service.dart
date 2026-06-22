import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> hasInternetConnection() async {
    // connectivity_plus 6 returns a list of active connection types. The old
    // comparison treated that list as an enum, which made this check true even
    // when the device was offline.
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
