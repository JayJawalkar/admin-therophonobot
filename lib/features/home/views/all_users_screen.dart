import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUsersPage extends StatelessWidget {
  final bool showOnlyPremium;

  const AllUsersPage({super.key, this.showOnlyPremium = false});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('users');
    
    if (showOnlyPremium) {
      query = query.where('isPremium', isEqualTo: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(showOnlyPremium ? '👑 Premium Users' : '👥 All Users'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          // Cast documents to Map and filter
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            if (showOnlyPremium) {
              return data.containsKey('isPremium') && data['isPremium'] == true;
            }
            return true;
          }).toList();

          if (showOnlyPremium && users.isEmpty) {
            return const Center(child: Text('No premium users found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final data = user.data() as Map<String, dynamic>? ?? {};
                
                final name = data['name'] ?? 'No Name';
                final email = data['email'] ?? 'No Email';
                final phone = data['phone'] ?? 'No Phone';
                final isPremium = data['isPremium'] == true;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: isPremium ? Colors.amber.shade700 : Colors.grey.shade300,
                      child: Icon(
                        isPremium ? Icons.workspace_premium : Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isPremium
                        ? const Icon(Icons.diamond_rounded, color: Colors.amber, size: 32)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}