import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignColorsScreen extends StatefulWidget {
  const AssignColorsScreen({super.key});

  @override
  State<AssignColorsScreen> createState() => _AssignColorsScreenState();
}

class _AssignColorsScreenState extends State<AssignColorsScreen> {
  Color selectedAppBarColor = Colors.blue;
  Color selectedBottomNavColor = Colors.blue;
  bool isSaving = false;
  bool hasColorChanged = false;
  bool isColorSetToday = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('theme_colors')
              .get();

      if (doc.exists) {
        // Load colors
        final appBarColorValue = doc.data()?['appBarColor'];
        final bottomNavColorValue = doc.data()?['bottomNavColor'];
        if (appBarColorValue != null) {
          selectedAppBarColor = Color(appBarColorValue);
        }
        if (bottomNavColorValue != null) {
          selectedBottomNavColor = Color(bottomNavColorValue);
        }

        // Check and reset daily flag
        final lastUpdated =
            (doc.data()?['lastUpdated'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);

        if (lastUpdated != null && lastUpdated.isBefore(todayMidnight)) {
          // Reset flag if last update was before today
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('theme_colors')
              .update({'isColorSetToday': false});
          setState(() => isColorSetToday = false);
        } else {
          // Set flag based on Firestore value
          setState(
            () => isColorSetToday = doc.data()?['isColorSetToday'] ?? false,
          );
        }
      }
    } catch (e) {
      e.toString();
    }
  }

  Future<void> _saveColors() async {
    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('theme_colors')
          .set({
            'appBarColor': selectedAppBarColor.value,
            'bottomNavColor': selectedBottomNavColor.value,
            'lastUpdated': FieldValue.serverTimestamp(),
            'isColorSetToday': true, // Add flag to Firestore
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colors saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving colors: $e')));
    } finally {
      setState(() {
        isSaving = false;
        hasColorChanged = false;
        isColorSetToday = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Colors'),
        backgroundColor: selectedAppBarColor,
        actions: [
          if (hasColorChanged && !isColorSetToday)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                onPressed: isSaving ? null : _saveColors,
                child:
                    isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text('Save Changes'),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isColorSetToday)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Colors already set today. Changes will take effect tomorrow after midnight.',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ),
            Card(
              child: ListTile(
                title: const Text('AppBar Color'),
                subtitle: const Text('Tap to change'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedAppBarColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => _showColorPicker(isAppBar: true),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Bottom Navigation Color'),
                subtitle: const Text('Tap to change'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedBottomNavColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => _showColorPicker(isAppBar: false),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  () => _showColorPicker(isAppBar: true, sameForBoth: true),
              icon: const Icon(Icons.color_lens),
              label: const Text('Set Same Color for Both'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: selectedBottomNavColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showColorPicker({required bool isAppBar, bool sameForBoth = false}) {
    Color tempAppBarColor = selectedAppBarColor;
    Color tempBottomNavColor = selectedBottomNavColor;
    bool sameColorForBoth = sameForBoth;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  sameForBoth
                      ? 'Set Same Color'
                      : 'Change ${isAppBar ? 'AppBar' : 'BottomNav'} Color',
                ),
                content: SizedBox(
                  width: 300,
                  height: sameForBoth ? 300 : 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!sameForBoth)
                        CheckboxListTile(
                          value: sameColorForBoth,
                          onChanged:
                              (value) => setState(
                                () => sameColorForBoth = value ?? false,
                              ),
                          title: const Text('Apply to both'),
                        ),
                      Expanded(
                        child: ColorPicker(
                          pickerColor:
                              isAppBar ? tempAppBarColor : tempBottomNavColor,
                          onColorChanged: (color) {
                            setState(() {
                              if (sameColorForBoth) {
                                tempAppBarColor = color;
                                tempBottomNavColor = color;
                              } else {
                                if (isAppBar) {
                                  tempAppBarColor = color;
                                } else {
                                  tempBottomNavColor = color;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      this.setState(() {
                        selectedAppBarColor = tempAppBarColor;
                        selectedBottomNavColor = tempBottomNavColor;
                        hasColorChanged = true;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  static final List<Color> colorOptions = [
    ...Colors.primaries,
    ...Colors.accents,
    Colors.black,
    Colors.white,
    Colors.transparent,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: colorOptions.length,
      itemBuilder: (context, index) {
        final color = colorOptions[index];
        return InkWell(
          onTap: () => onColorChanged(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: pickerColor == color ? Colors.blue : Colors.grey,
                width: pickerColor == color ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                color == Colors.transparent
                    ? const Icon(Icons.block, color: Colors.red)
                    : null,
          ),
        );
      },
    );
  }
}
