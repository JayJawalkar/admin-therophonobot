import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController educationController = TextEditingController(); // Comma-separated
  final TextEditingController languagesController = TextEditingController(); // Comma-separated

  bool isSaving = false;

  void saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': nameController.text.trim(),
        'about': aboutController.text.trim(),
        'availability': availabilityController.text.trim(),
        'experience': experienceController.text.trim(),
        'hospital': hospitalController.text.trim(),
        'education': educationController.text.trim().split(',').map((e) => e.trim()).toList(),
        'languages': languagesController.text.trim().split(',').map((e) => e.trim()).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor added successfully')),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, 'Name'),
              _buildTextField(aboutController, 'About', maxLines: 5),
              _buildTextField(availabilityController, 'Availability (e.g. Mon–Sat)'),
              _buildTextField(experienceController, 'Experience (e.g. 20 years)'),
              _buildTextField(hospitalController, 'Hospital (e.g. Fortis Hospital, Noida)'),
              _buildTextField(educationController, 'Education (comma separated)'),
              _buildTextField(languagesController, 'Languages (comma separated)'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : saveDoctor,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
