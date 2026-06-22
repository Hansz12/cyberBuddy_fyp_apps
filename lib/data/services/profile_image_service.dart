import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const _pathKeyPrefix = 'profile_image_path_';

  Future<File?> loadImage({String? userId}) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUserId == null || resolvedUserId.isEmpty) return null;

    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString(_pathKeyFor(resolvedUserId));

    if (path == null) return null;

    final image = File(path);
    return image.existsSync() ? image : null;
  }

  Future<File> saveImage(File source, {String? userId}) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      throw StateError('A signed-in user is required to save a profile image.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final image = File(
      '${directory.path}${Platform.pathSeparator}profile_$resolvedUserId.jpg',
    );

    await source.copy(image.path);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pathKeyFor(resolvedUserId), image.path);

    return image;
  }

  Future<void> removeImage({String? userId}) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUserId == null || resolvedUserId.isEmpty) return;

    final image = await loadImage(userId: resolvedUserId);
    if (image != null && await image.exists()) {
      await image.delete();
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pathKeyFor(resolvedUserId));
  }

  String _pathKeyFor(String userId) => '$_pathKeyPrefix$userId';
}
