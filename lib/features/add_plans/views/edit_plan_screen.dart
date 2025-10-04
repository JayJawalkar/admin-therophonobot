import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPlanScreen extends StatefulWidget {
  final String planId;
  const EditPlanScreen({super.key, required this.planId});

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
  bool _isPopular = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response =
          await _supabase
              .from('plans')
              .select()
              .eq('id', widget.planId)
              .single();

      _titleController.text = response['title'];
      _priceController.text = response['price'].toString();
      _durationController.text = response['duration'];
      setState(() {
        benefits = List<String>.from(response['benefits']);
        _isPopular = response['is_popular'] ?? false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePlan() async {
    if (_formKey.currentState!.validate() && benefits.isNotEmpty) {
      try {
        await _supabase
            .from('plans')
            .update({
              'title': _titleController.text,
              'price': double.parse(_priceController.text),
              'duration': _durationController.text,
              'benefits': benefits,
              'is_popular': _isPopular,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.planId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
      appBar: AppBar(
        title: const Text('Edit Plan'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _updatePlan),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Plan Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plan title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isPopular,
                    onChanged: (value) {
                      setState(() {
                        _isPopular = value!;
                      });
                    },
                  ),
                  const Text('Mark as Popular Plan'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Plan Benefits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _benefitController,
                      decoration: const InputDecoration(
                        labelText: 'Add benefit',
                        prefixIcon: Icon(Icons.add_circle_outline),
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addBenefit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _addBenefit,
                  ),
                ],
              ),
              if (benefits.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      benefits.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => _removeBenefit(entry.key),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updatePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
