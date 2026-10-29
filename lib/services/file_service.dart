import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class FileService {
  static final supabase = Supabase.instance.client;
  static final picker = ImagePicker();

  static Future<String?> uploadImage({required String bucket, required String path}) async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final bytes = await File(image.path).readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      
      await supabase.storage.from(bucket).uploadBinary(
        '$path/$fileName',
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from(bucket).getPublicUrl('$path/$fileName');
    } catch (e) {
      return null;
    }
  }

  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      await supabase.storage.from(bucket).uploadBinary(
        '$path/$fileName',
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from(bucket).getPublicUrl('$path/$fileName');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteFile({required String bucket, required String path}) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
