import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const _pathKey = 'profile_image_path';

  Future<File?> loadImage() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString(_pathKey);

    if (path == null) return null;

    final image = File(path);
    return image.existsSync() ? image : null;
  }

  Future<File> saveImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final image = File('${directory.path}${Platform.pathSeparator}profile_$userId.jpg');

    await source.copy(image.path);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pathKey, image.path);

    return image;
  }

  Future<void> removeImage() async {
    final image = await loadImage();
    if (image != null && await image.exists()) {
      await image.delete();
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pathKey);
  }
}
