// edit_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPlanScreen extends StatefulWidget {
  final DocumentReference docRef;
  const EditPlanScreen({super.key, required this.docRef});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _benefitController = TextEditingController();
  List<String> benefits = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final doc = await widget.docRef.get();
    final data = doc.data() as Map<String, dynamic>;
    _titleController.text = data['title'];
    _priceController.text = data['price'].toString();
    _durationController.text = data['duration'];
    setState(() => benefits = List<String>.from(data['benefits']));
  }

  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate() && benefits.isNotEmpty) {
      await widget.docRef.update({
        'title': _titleController.text,
        'price': double.parse(_priceController.text),
        'duration': _durationController.text,
        'benefits': benefits,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully')),
      );
      Navigator.pop(context);
    } else if (benefits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one benefit')),
      );
    }
  }

  void _addBenefit() {
    if (_benefitController.text.isNotEmpty) {
      setState(() {
        benefits.add(_benefitController.text);
        _benefitController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() => benefits.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Course')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Course Title'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price (₹)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(labelText: 'Duration'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Course Benefits'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _benefitController,
                      decoration: InputDecoration(
                        labelText: 'Add benefit',
                        prefixIcon: Icon(Icons.add_circle_outline),
                      ),
                      onFieldSubmitted: (_) => _addBenefit(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                    onPressed: _addBenefit,
                  ),
                ],
              ),
              if (benefits.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: benefits.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeBenefit(entry.key),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateCourse,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}