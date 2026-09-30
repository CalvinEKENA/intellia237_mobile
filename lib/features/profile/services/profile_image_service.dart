import 'dart:typed_data';

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

  /// Ouvre le Photo Picker système (galerie).
  ///
  /// Octets plutôt que fichier : un navigateur n'a pas de système de
  /// fichiers (application web, 23/09/2026) ; le téléphone s'en accommode.
  Future<Uint8List?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Ouvre la caméra
  Future<Uint8List?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Upload vers Firebase Storage + mise à jour Firestore
  Future<String?> uploadProfileImage(Uint8List imageBytes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Utilisateur non connecté');

    // Référence Storage : avatars/{uid}/profile.jpg
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');

    final uploadTask = await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Mise à jour Firestore
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }

  /// Supprime l'ancienne photo du Storage
  Future<void> deleteOldProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _storage.ref().child('avatars/$uid/profile.jpg').delete();
    } catch (_) {
      // Le fichier peut déjà avoir été supprimé ; le profil Firestore doit
      // tout de même être nettoyé pour ne pas garder une URL cassée.
    }
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
