import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController languagesController = TextEditingController();

  File? _selectedImage;
  Uint8List? _imageBytes;
  bool isSaving = false;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if ((_selectedImage == null && _imageBytes == null) || 
        (_selectedImage == null && kIsWeb && _imageBytes == null)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Add Photo', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    if (kIsWeb) {
      return Image.memory(
        _imageBytes!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        _selectedImage!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }
  }

  Future<String?> _uploadImage() async {
    try {
      if (kIsWeb) {
        if (_imageBytes == null) return null;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('doctor_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await storageRef.putData(_imageBytes!);
        return await uploadTask.ref.getDownloadURL();
      } else {
        if (_selectedImage == null) return null;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('doctor_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await storageRef.putFile(_selectedImage!);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      // Upload image first if selected
      if ((_selectedImage != null) || (_imageBytes != null && kIsWeb)) {
        _imageUrl = await _uploadImage();
      }

      await FirebaseFirestore.instance.collection('doctors').add({
        'name': nameController.text.trim(),
        'about': aboutController.text.trim(),
        'availability': availabilityController.text.trim(),
        'experience': experienceController.text.trim(),
        'hospital': hospitalController.text.trim(),
        'education': educationController.text.trim().split(',').map((e) => e.trim()).toList(),
        'languages': languagesController.text.trim().split(',').map((e) => e.trim()).toList(),
        'imageUrl': _imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
        _imageUrl = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Doctor'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doctor Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Image Upload Section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImagePreview(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (_selectedImage == null && _imageBytes == null) 
                                  ? 'No image selected' 
                                  : 'Image selected',
                              style: TextStyle(
                                color: (_selectedImage == null && _imageBytes == null) 
                                    ? Colors.grey 
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Fields
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          SizedBox(
                            width: 400,
                            child: _buildTextField(nameController, 'Full Name'),
                          ),
                          SizedBox(
                            width: 400,
                            child: _buildTextField(
                              experienceController,
                              'Experience (e.g. 20 years)',
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: _buildTextField(
                              availabilityController,
                              'Availability (e.g. Mon–Sat 9AM-5PM)',
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: _buildTextField(
                              hospitalController,
                              'Hospital/Clinic',
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: _buildTextField(
                              educationController,
                              'Education (comma separated)',
                              hintText: 'MD, MBBS, PhD',
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: _buildTextField(
                              languagesController,
                              'Languages (comma separated)',
                              hintText: 'English, Hindi, Spanish',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        aboutController,
                        'About Doctor',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : saveDoctor,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 20),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Doctor',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}