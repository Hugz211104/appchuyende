import 'dart:io';
import 'package:chuyende/services/storage_service.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _handleController;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  File? _profileImageFile;
  File? _coverImageFile;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _handleController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _displayNameController.text = _userData?['displayName'] ?? '';
          _bioController.text = _userData?['bio'] ?? '';
          _handleController.text = _userData?['handle'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, Function(File) onImagePicked) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  void _showImageSourcePicker(Function(File) onImagePicked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () {
                _pickImage(ImageSource.gallery, onImagePicked);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () {
                _pickImage(ImageSource.camera, onImagePicked);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? newPhotoURL = _userData?['photoURL'];
      String? newCoverPhotoURL = _userData?['coverPhotoUrl'];

      if (_profileImageFile != null) {
        newPhotoURL = await _storageService.uploadProfileImage(_profileImageFile!);
      }
      if (_coverImageFile != null) {
        newCoverPhotoURL = await _storageService.uploadCoverImage(_coverImageFile!);
      }
      
      final newDisplayName = _displayNameController.text.trim();
      final newBio = _bioController.text.trim();
      final newHandle = _handleController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': newDisplayName,
        'bio': newBio,
        'handle': newHandle,
        'photoURL': newPhotoURL,
        'coverPhotoUrl': newCoverPhotoURL,
      });

      if (newDisplayName != user.displayName || newPhotoURL != user.photoURL) {
        await user.updateDisplayName(newDisplayName);
        await user.updatePhotoURL(newPhotoURL);
      }

      if (mounted) {
        await CustomDialog.show(
          context,
          title: 'Thành công',
          description: 'Hồ sơ đã được cập nhật thành công!',
          dialogType: DialogType.SUCCESS,
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context,
          title: 'Cập nhật thất bại',
          description: 'Đã xảy ra lỗi: $e',
          dialogType: DialogType.ERROR,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          if (!_isSaving) TextButton(onPressed: _saveProfile, child: const Text('LƯU')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImagePickers(),
                    const SizedBox(height: 70),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Tên hiển thị', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên hiển thị' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _handleController,
                      decoration: const InputDecoration(labelText: 'Tên người dùng', border: OutlineInputBorder(), prefixText: '@'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên người dùng';
                        if (value.contains(' ')) return 'Tên người dùng không được chứa khoảng trắng';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Tiểu sử', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePickers() {
    final String coverPhotoUrl = _userData?['coverPhotoUrl'] ?? '';
    final String? photoURL = _userData?['photoURL'];

    ImageProvider<Object> coverImageProvider;
    if (_coverImageFile != null) {
      coverImageProvider = FileImage(_coverImageFile!);
    } else if (coverPhotoUrl.isNotEmpty) {
      coverImageProvider = NetworkImage(coverPhotoUrl);
    } else {
      coverImageProvider = const AssetImage('assets/placeholder.png'); 
    }

    ImageProvider<Object>? profileImageProvider;
    if (_profileImageFile != null) {
      profileImageProvider = FileImage(_profileImageFile!);
    } else if (photoURL != null && photoURL.isNotEmpty) {
      profileImageProvider = NetworkImage(photoURL);
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => _showImageSourcePicker((file) => setState(() => _coverImageFile = file)),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              image: DecorationImage(image: coverImageProvider, fit: BoxFit.cover, onError: (e,s) {}),
            ),
            child: const Center(child: Icon(Icons.camera_alt, color: Colors.white70, size: 30)),
          ),
        ),
        Positioned(
          bottom: -50,
          child: GestureDetector(
            onTap: () => _showImageSourcePicker((file) => setState(() => _profileImageFile = file)),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: profileImageProvider,
                child: (profileImageProvider == null) ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
