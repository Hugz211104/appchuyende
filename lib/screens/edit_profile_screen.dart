import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Image related variables will be added later
  // File? _profileImage;
  // File? _coverImage;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      Navigator.of(context).pop();
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _displayNameController.text = _userData?['displayName'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Logic to save profile will be added here
    if (_formKey.currentState!.validate()) {
      // TODO: Implement update logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('SAVE'),
          ),
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
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePickers() {
    final String coverPhotoUrl = _userData?['coverPhotoUrl'] ?? 'https://via.placeholder.com/500x200.png?text=Cover+Photo';
    final String? photoURL = _userData?['photoURL'];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        // Cover Image
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            image: DecorationImage(
              image: NetworkImage(coverPhotoUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white70, size: 30),
              onPressed: () { /* TODO: Pick cover image */ },
            ),
          ),
        ),
        // Profile Image
        Positioned(
          bottom: -40,
          left: 20,
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: (photoURL != null) ? NetworkImage(photoURL) : null,
              child: Stack(
                children: [
                  if (photoURL == null) const Icon(Icons.person, size: 50, color: Colors.white),
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white70),
                      onPressed: () { /* TODO: Pick profile image */ },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
