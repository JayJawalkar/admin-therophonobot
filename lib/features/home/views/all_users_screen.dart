import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllUsersPage extends StatelessWidget {
  final bool showOnlyPremium;
  final bool expiringSoonOnly;

  const AllUsersPage({
    super.key,
    this.showOnlyPremium = false,
    this.expiringSoonOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final Size size=MediaQuery.of(context).size;
    final Query query = showOnlyPremium
        ? FirebaseFirestore.instance
            .collection('users')
            .where('isPremium', isEqualTo: true)
        : FirebaseFirestore.instance.collection('users');

    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));

    final horizontalScroll = ScrollController();
    final verticalScroll = ScrollController();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          showOnlyPremium
              ? (expiringSoonOnly ? '⏳ Expiring Premium Users' : '👑 Premium Users')
              : '👥 All Users',
        ),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
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

          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final isPremium = data['isPremium'] == true;

            if (showOnlyPremium && !isPremium) return false;

            if (expiringSoonOnly) {
              final ts = data['premiumExpiresAt'];
              if (ts is Timestamp) {
                final expiryDate = ts.toDate();
                return expiryDate.isAfter(now) && expiryDate.isBefore(cutoff);
              }
              return false;
            }

            return true;
          }).toList();

          if (users.isEmpty) {
            return Center(
              child: Text(
                showOnlyPremium
                    ? (expiringSoonOnly
                        ? 'No premium users expiring soon.'
                        : 'No premium users found.')
                    : 'No users found.',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          return Scrollbar(
            controller: verticalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: verticalScroll,
              padding: const EdgeInsets.all(24),
              child: Scrollbar(
                controller: horizontalScroll,
                thumbVisibility: true,
                notificationPredicate: (_) => true,
                child: SingleChildScrollView(
                  controller: horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:  BoxConstraints(minWidth: size.width-100),
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey[200]),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(
                          label: Text('Name',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Email',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Phone',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Premium',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Expires At',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: users.map((user) {
                        final data = user.data() as Map<String, dynamic>? ?? {};
                        final name = data['name'] ?? 'No Name';
                        final email = data['email'] ?? 'No Email';
                        final phone = data['phone'] ?? 'No Phone';
                        final isPremium = data['isPremium'] == true;

                        String expiryStr = '—';
                        bool isExpiringSoon = false;

                        if (isPremium &&
                            data['premiumExpiresAt'] is Timestamp) {
                          final expiryDate =
                              (data['premiumExpiresAt'] as Timestamp).toDate();
                          expiryStr =
                              DateFormat('dd MMM yyyy, hh:mm a').format(expiryDate);
                          isExpiringSoon = expiryDate.isAfter(now) &&
                              expiryDate.isBefore(cutoff);
                        }

                        return DataRow(cells: [
                          DataCell(Text(name)),
                          DataCell(Text(email)),
                          DataCell(Text(phone)),
                          DataCell(
                            isPremium
                                ? const Icon(Icons.verified, color: Colors.green)
                                : const Icon(Icons.close, color: Colors.red),
                          ),
                          DataCell(Text(expiryStr)),
                          DataCell(
                            isPremium
                                ? isExpiringSoon
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.redAccent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Expiring Soon',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                : const Text('—'),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
