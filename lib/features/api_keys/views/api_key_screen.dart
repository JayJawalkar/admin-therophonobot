import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final CollectionReference apiKeys =
      FirebaseFirestore.instance.collection('apikeys');

  // Function to edit API Key
  Future<void> _updateApiKey(String docId, String keyName, String currentValue,
      [String? currentRegion]) async {
    TextEditingController keyController = TextEditingController(text: currentValue);
    TextEditingController? regionController;

    if (keyName == "speechace" && currentRegion != null) {
      regionController = TextEditingController(text: currentRegion);
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $keyName Key"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(labelText: "$keyName API Key"),
                ),
                if (keyName == "speechace")
                  TextField(
                    controller: regionController,
                    decoration: InputDecoration(labelText: "Region"),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (keyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("API Key cannot be empty")),
                  );
                  return;
                }

                try {
                  await apiKeys.doc(docId).update({
                    "key": keyController.text.trim(),
                    if (keyName == "speechace" && regionController != null)
                      "region": regionController.text.trim(),
                  });

                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$keyName key updated successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update key: $e")),
                  );
                }
              },
              child: Text("Save"),
            )
          ],
        );
      },
    );
  }

  // Widget to show key with copy button
  Widget _buildKeyRow(BuildContext context, String service, String key,
      VoidCallback onEdit, String? region) {
    return ListTile(
      title: Text("$service API Key", style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(key),
          if (region != null) Text("Region: $region"),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$service key copied to clipboard")),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage API Keys")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: apiKeys.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No API keys found."));
            }

            Map<String, dynamic> keysMap = {};
            snapshot.data!.docs.forEach((doc) {
              keysMap[doc.id] = doc.data() as Map<String, dynamic>;
            });

            return ListView(
              children: [
                // Razorpay Key
                _buildKeyRow(
                  context,
                  "Razorpay",
                  keysMap['razorpay']?['key'] ?? "N/A",
                  () => _updateApiKey(
                    'razorpay',
                    'razorpay',
                    keysMap['razorpay']?['key'] ?? "",
                  ),
                  null,
                ),

                // Speechace Key
                _buildKeyRow(
                  context,
                  "Speechace",
                  keysMap['speechace']?['key'] ?? "N/A",
                  () => _updateApiKey(
                    'speechace',
                    'speechace',
                    keysMap['speechace']?['key'] ?? "",
                    keysMap['speechace']?['region'],
                  ),
                  keysMap['speechace']?['region'] ?? "N/A",
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}