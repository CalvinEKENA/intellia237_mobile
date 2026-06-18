import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class ProfileImageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileImageService() {
    _initPhotoPicker();
  }

  void _initPhotoPicker() {
    final platform = ImagePickerPlatform.instance;
    if (platform is ImagePickerAndroid) {
      platform.useAndroidPhotoPicker = true;
    }
  }

  /// Ouvre le Photo Picker système (galerie)
  Future<File?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return null;
    return File(file.path);
  }

  /// Ouvre la caméra
  Future<File?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return null;
    return File(file.path);
  }

  /// Upload vers Firebase Storage + mise à jour Firestore
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Référence Storage : avatars/{uid}/profile.jpg
      final ref = _storage.ref().child('avatars/$uid/profile.jpg');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Mise à jour Firestore
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime l'ancienne photo du Storage
  Future<void> deleteOldProfileImage() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _storage.ref().child('avatars/$uid/profile.jpg').delete();
    } catch (_) {
      // Pas d'image existante, on ignore
    }
  }
}
