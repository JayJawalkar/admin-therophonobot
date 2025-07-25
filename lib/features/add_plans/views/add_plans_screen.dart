import 'package:admin_therophonobot/features/add_plans/views/edit_plan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddPlansScreen extends StatefulWidget {
  const AddPlansScreen({super.key});
  @override
  State<AddPlansScreen> createState() => _AddPlansScreenState();
}

class _AddPlansScreenState extends State<AddPlansScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _benefitController = TextEditingController();
  List<String> benefits = [];
  final CollectionReference plans = FirebaseFirestore.instance.collection(
    'plans',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate() && benefits.isNotEmpty) {
      await plans.add({
        'title': _titleController.text,
        'price': double.parse(_priceController.text),
        'duration': _durationController.text,
        'benefits': benefits,
        'createdAt': Timestamp.now(),
      });
      // Clear form
      _titleController.clear();
      _priceController.clear();
      _durationController.clear();
      _benefitController.clear();
      setState(() => benefits = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course added successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else if (benefits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one benefit'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
    setState(() {
      benefits.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanOptions(context),
        tooltip: 'Manage Plans',
        child: const Icon(Icons.more_vert),
      ),

      appBar: AppBar(title: const Text('Add Plans'), centerTitle: true),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  Expanded(flex: 2, child: _buildCourseList()),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Course',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildFormField(
                              controller: _titleController,
                              label: 'Course Title',
                              hint: 'Enter course title',
                              icon: Icons.title,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _priceController,
                                    label: 'Price (₹)',
                                    hint: '0.00',
                                    icon: Icons.abc,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _durationController,
                                    label: 'Duration',
                                    hint: 'e.g. 3 months',
                                    icon: Icons.timer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Course Benefits',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _benefitController,
                                    decoration: InputDecoration(
                                      labelText: 'Add benefit',
                                      prefixIcon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                    ),
                                    onFieldSubmitted: (_) => _addBenefit(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: theme.primaryColor,
                                    size: 40,
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
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onDeleted:
                                            () => _removeBenefit(entry.key),
                                        backgroundColor: theme.primaryColor
                                            .withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addCourse,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Course',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 24),
                  _buildCourseList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Plan'),
                onTap: () {
                  Navigator.pop(context);
                  _selectPlanToEdit(); // Define this
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Plan'),
                onTap: () {
                  Navigator.pop(context);
                  _selectPlanToDelete(); // Define this
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectPlanToEdit() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select a plan to edit'),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: plans.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['title']),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToEdit(doc.reference);
                          },
                        );
                      }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _selectPlanToDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select a plan to delete'),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: plans.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['title']),
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(doc.reference);
                          },
                        );
                      }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Existing Courses',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: plans.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No courses added yet'));
                }
                return isDesktop
                    ? _buildDesktopCourseTable(snapshot.data!.docs)
                    : _buildMobileCourseList(snapshot.data!.docs);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCourseTable(List<QueryDocumentSnapshot> docs) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Price',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Duration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Benefits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          DataColumn(
            label: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: const Text('Actions'),
            ),
          ),
        ],
        rows:
            docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(Text(data['title'])),
                  DataCell(Text(currencyFormat.format(data['price']))),
                  DataCell(Text(data['duration'])),
                  DataCell(
                    Tooltip(
                      message: data['benefits'].join('\n'),
                      child: Text(
                        '${data['benefits'].length} benefits',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  // Inside _buildDesktopCourseTable
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => _navigateToEdit(doc.reference),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDelete(doc.reference),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMobileCourseList(List<QueryDocumentSnapshot> docs) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['title'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEdit(doc.reference),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(doc.reference),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Price: ',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    Text(
                      currencyFormat.format(data['price']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Duration: ',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    Text(
                      data['duration'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Benefits:',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      (data['benefits'] as List).take(3).map((benefit) {
                        return Chip(
                          label: Text(benefit),
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                ),
                if ((data['benefits'] as List).length > 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${(data['benefits'] as List).length - 3} more',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToEdit(DocumentReference docRef) {
    // Navigate to an EditPlanScreen (not implemented in the current code)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPlanScreen(docRef: docRef)),
    );
  }

  Future<void> _confirmDelete(DocumentReference docRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this course?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await docRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course deleted successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
