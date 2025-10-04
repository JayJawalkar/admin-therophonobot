// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Function to edit API Key
  Future<void> _updateApiKey(
    String serviceName,
    String currentValue, [
    String? currentRegion,
  ]) async {
    TextEditingController keyController = TextEditingController(
      text: currentValue,
    );
    TextEditingController? regionController;

    if (serviceName == "speechace" && currentRegion != null) {
      regionController = TextEditingController(text: currentRegion);
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $serviceName Key"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: "$serviceName API Key",
                  ),
                ),
                if (serviceName == "speechace")
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
                  // Update existing record
                  await _supabase
                      .from('api_keys')
                      .update({
                        'api_key': keyController.text.trim(),
                        if (serviceName == "speechace" &&
                            regionController != null)
                          'region': regionController.text.trim(),
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('service_name', serviceName);

                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$serviceName key updated successfully"),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update key: $e")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Widget to show key with copy button
  Widget _buildKeyRow(
    BuildContext context,
    String service,
    String key,
    VoidCallback onEdit,
    String? region,
  ) {
    return ListTile(
      title: Text(
        "$service API Key",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(key),
          if (region != null && region.isNotEmpty && region != "N/A")
            Text("Region: $region"),
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
          IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchApiKeys(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Error loading API keys: ${snapshot.error}"),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No API keys found."));
            }

            // Convert list to map for easier access
            Map<String, Map<String, dynamic>> keysMap = {};
            for (var keyData in snapshot.data!) {
              keysMap[keyData['service_name']] = keyData;
            }

            return ListView(
              children: [
                // Razorpay Key
                _buildKeyRow(
                  context,
                  "Razorpay",
                  keysMap['razorpay']?['api_key'] ?? "N/A",
                  () => _updateApiKey(
                    'razorpay',
                    keysMap['razorpay']?['api_key'] ?? "",
                  ),
                  null,
                ),

                // Speechace Key
                _buildKeyRow(
                  context,
                  "Speechace",
                  keysMap['speechace']?['api_key'] ?? "N/A",
                  () => _updateApiKey(
                    'speechace',
                    keysMap['speechace']?['api_key'] ?? "",
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

  Future<List<Map<String, dynamic>>> _fetchApiKeys() async {
    final response = await _supabase
        .from('api_keys')
        .select()
        .eq('is_active', true);

    return response;
  }
}
