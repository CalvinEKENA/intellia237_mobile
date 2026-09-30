import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../presentation/widgets/profile_surfaces.dart';
import '../services/profile_image_service.dart';
import 'profile_avatar.dart';

enum _PhotoAction { gallery, camera, remove }

class AvatarPickerWidget extends ConsumerStatefulWidget {
  const AvatarPickerWidget({
    super.key,
    this.currentPhotoUrl,
    this.radius = 56,
    this.onUploaded,
    this.service,
  });

  final String? currentPhotoUrl;
  final double radius;
  final void Function(String newPhotoUrl)? onUploaded;
  final ProfileImageService? service;

  @override
  ConsumerState<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends ConsumerState<AvatarPickerWidget> {
  // Displaying an avatar never initializes Firebase or a camera plugin.
  ProfileImageService? _imageService;
  ProfileImageService get _service =>
      _imageService ??= widget.service ?? ProfileImageService();
  Uint8List? _localImage;
  bool _removed = false;
  bool _isLoading = false;

  @override
  void didUpdateWidget(AvatarPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPhotoUrl != widget.currentPhotoUrl) {
      _localImage = null;
      _removed = false;
    }
  }

  Future<void> _showPickerOptions() async {
    profileSelectionHaptic(ref);
    final copy = context.l10n;
    final choice = await Navigator.of(context, rootNavigator: true)
        .push<_PhotoAction>(
          ProfileActionSheetRoute<_PhotoAction>(
            reduced: profileMotionReduced(context, ref),
            builder: (sheetContext) => CupertinoActionSheet(
              title: Text(copy.profilePhotoTitle),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () =>
                      Navigator.pop(sheetContext, _PhotoAction.gallery),
                  child: Text(copy.profilePhotoGallery),
                ),
                CupertinoActionSheetAction(
                  onPressed: () =>
                      Navigator.pop(sheetContext, _PhotoAction.camera),
                  child: Text(copy.profilePhotoCamera),
                ),
                if (!_removed &&
                    (widget.currentPhotoUrl?.isNotEmpty == true ||
                        _localImage != null))
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () =>
                        Navigator.pop(sheetContext, _PhotoAction.remove),
                    child: Text(copy.profilePhotoRemove),
                  ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(copy.cancelLabel),
              ),
            ),
          ),
        );
    if (!mounted || choice == null) return;
    if (choice == _PhotoAction.remove) {
      await _removePhoto();
    } else {
      await _pickAndUpload(fromCamera: choice == _PhotoAction.camera);
    }
  }

  Future<void> _pickAndUpload({required bool fromCamera}) async {
    final previous = _localImage;
    setState(() => _isLoading = true);
    try {
      final file = fromCamera
          ? await _service.pickFromCamera()
          : await _service.pickFromGallery();
      if (!mounted || file == null) return;
      setState(() => _localImage = file);
      final url = await _service.uploadProfileImage(file);
      if (!mounted) return;
      if (url == null || url.isEmpty) throw StateError('photo-upload-empty');
      setState(() => _removed = false);
      widget.onUploaded?.call(url);
      _message(context.l10n.profilePhotoUpdated);
    } catch (_) {
      if (!mounted) return;
      // Failed network saves must not masquerade as a persisted avatar.
      setState(() => _localImage = previous);
      _message(context.l10n.profilePhotoError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isLoading = true);
    try {
      await _service.deleteOldProfileImage();
      if (!mounted) return;
      setState(() {
        _localImage = null;
        _removed = true;
      });
      widget.onUploaded?.call('');
      _message(context.l10n.profilePhotoUpdated);
    } catch (_) {
      if (mounted) _message(context.l10n.profilePhotoRemoveError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.profilePhotoTitle,
    child: CupertinoButton(
      key: const ValueKey('profile-avatar-picker'),
      padding: EdgeInsets.zero,
      onPressed: _isLoading ? null : _showPickerOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ProfileAvatar(
            radius: widget.radius,
            photoUrl: _removed ? null : widget.currentPhotoUrl,
            image: _localImage == null ? null : MemoryImage(_localImage!),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: IntelliaColors.brandIndigo,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: _isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
    ),
  );
}
