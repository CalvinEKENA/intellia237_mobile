import 'dart:io';
import 'package:flutter/material.dart';
import '../services/profile_image_service.dart';

class AvatarPickerWidget extends StatefulWidget {
  final String? currentPhotoUrl;
  final double radius;
  final void Function(String newPhotoUrl)? onUploaded;

  const AvatarPickerWidget({
    super.key,
    this.currentPhotoUrl,
    this.radius = 56,
    this.onUploaded,
  });

  @override
  State<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends State<AvatarPickerWidget> {
  final ProfileImageService _service = ProfileImageService();

  File? _localImage;
  bool _isLoading = false;

  Future<void> _showPickerOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Photo de profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library_outlined),
              ),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(fromCamera: false);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.camera_alt_outlined),
              ),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(fromCamera: true);
              },
            ),
            if (widget.currentPhotoUrl != null || _localImage != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete_outline, color: Colors.white),
                ),
                title: const Text(
                  'Supprimer la photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload({required bool fromCamera}) async {
    File? file;

    if (fromCamera) {
      file = await _service.pickFromCamera();
    } else {
      file = await _service.pickFromGallery();
    }

    if (file == null) return;

    setState(() {
      _localImage = file;
      _isLoading = true;
    });

    try {
      final url = await _service.uploadProfileImage(file);
      if (url != null) {
        widget.onUploaded?.call(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isLoading = true);
    try {
      await _service.deleteOldProfileImage();
      setState(() => _localImage = null);
      widget.onUploaded?.call('');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _showPickerOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _localImage != null
                ? FileImage(_localImage!)
                : (widget.currentPhotoUrl != null &&
                      widget.currentPhotoUrl!.isNotEmpty)
                ? NetworkImage(widget.currentPhotoUrl!) as ImageProvider
                : null,
            child: _isLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : (_localImage == null &&
                      (widget.currentPhotoUrl == null ||
                          widget.currentPhotoUrl!.isEmpty))
                ? Icon(
                    Icons.person,
                    size: widget.radius,
                    color: Colors.grey.shade500,
                  )
                : null,
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
