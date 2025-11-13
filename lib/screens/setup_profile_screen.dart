import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String? _gender;
  File? _image;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _dateOfBirth) {
      setState(() {
        _dateOfBirth = pickedDate;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        String? photoURL;
        if (_image != null) {
          final storageRef = FirebaseStorage.instance.ref().child('user_avatars').child('${user.uid}.jpg');
          await storageRef.putFile(_image!);
          photoURL = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _displayNameController.text,
          'handle': _handleController.text,
          'bio': _bioController.text,
          'dateOfBirth': _dateOfBirth != null ? Timestamp.fromDate(_dateOfBirth!) : null,
          'gender': _gender,
          'photoURL': photoURL,
          'profileCompleted': true, // Flag to indicate profile is set up
        }, SetOptions(merge: true));

        if (mounted) {
          // No need to navigate, AuthWrapper will handle it
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xảy ra lỗi: $e')),
          );
        }
      } finally {
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập Hồ sơ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên hiển thị' : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(labelText: 'Tên người dùng (@handle)'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên người dùng' : null,
                 autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Tiểu sử'),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(_dateOfBirth == null ? 'Chọn ngày sinh' : 'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(_dateOfBirth!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _gender = newValue;
                  });
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Hoàn tất'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
