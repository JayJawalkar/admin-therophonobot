import 'package:admin_therophonobot/features/home/service/block_user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllUsersPage extends StatefulWidget {
  final bool showOnlyPremium;
  final bool expiringSoonOnly;

  const AllUsersPage({
    super.key,
    this.showOnlyPremium = false,
    this.expiringSoonOnly = false,
  });

  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {

  // Function to increase premium validity
  Future<void> _increaseValidity(String userId, int daysToAdd) async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userData = await userDoc.get();

      if (userData.exists) {
        final data = userData.data()!;
        final currentExpiry = data['premiumExpiresAt'] as Timestamp?;
        final newExpiry =
            currentExpiry != null
                ? currentExpiry.toDate().add(Duration(days: daysToAdd))
                : DateTime.now().add(Duration(days: daysToAdd));

        await userDoc.update({
          'premiumExpiresAt': Timestamp.fromDate(newExpiry),
        });
      }
    } catch (e) {
      print('Error increasing validity: $e');
    }
  }

  Future<void> _blockUser(String uid) async {
    final result = await UserService.blockUser(uid);

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));
    } else {
      print(result["error"]);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${result["error"]}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final Query query =
        widget.showOnlyPremium
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
          widget.showOnlyPremium
              ? (widget.expiringSoonOnly
                  ? '⏳ Expiring Premium Users'
                  : '👑 Premium Users')
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

          final users =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final isPremium = data['isPremium'] == true;

                if (widget.showOnlyPremium && !isPremium) return false;

                if (widget.expiringSoonOnly) {
                  final ts = data['premiumExpiresAt'];
                  if (ts is Timestamp) {
                    final expiryDate = ts.toDate();
                    return expiryDate.isAfter(now) &&
                        expiryDate.isBefore(cutoff);
                  }
                  return false;
                }

                return true;
              }).toList();

          if (users.isEmpty) {
            return Center(
              child: Text(
                widget.showOnlyPremium
                    ? (widget.expiringSoonOnly
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
                    constraints: BoxConstraints(minWidth: size.width - 100),
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey[200],
                      ),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Phone',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Premium',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Expires At',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Block User',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows:
                          users.map((user) {
                            final data =
                                user.data() as Map<String, dynamic>? ?? {};
                            final name = data['name'] ?? 'No Name';
                            final email = data['email'] ?? 'No Email';
                            final phone = data['phone'] ?? 'No Phone';
                            final isPremium = data['isPremium'] == true;
                            final isBlocked = data['isBlocked'] == true;
                            final userId = user.id;

                            String expiryStr = '—';
                            bool isExpiringSoon = false;

                            if (isPremium &&
                                data['premiumExpiresAt'] is Timestamp) {
                              final expiryDate =
                                  (data['premiumExpiresAt'] as Timestamp)
                                      .toDate();
                              expiryStr = DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(expiryDate);
                              isExpiringSoon =
                                  expiryDate.isAfter(now) &&
                                  expiryDate.isBefore(cutoff);
                            }

                            return DataRow(
                              cells: [
                                DataCell(Text(name)),
                                DataCell(Text(email)),
                                DataCell(Text(phone)),
                                DataCell(
                                  isPremium
                                      ? const Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                      )
                                      : const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                ),
                                DataCell(Text(expiryStr)),
                                DataCell(
                                  isPremium
                                      ? isExpiringSoon
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withOpacity(0.1),
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
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
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
                                DataCell(
                                  isPremium
                                      ? PopupMenuButton(
                                        itemBuilder:
                                            (context) => [
                                              PopupMenuItem(
                                                child: const Text(
                                                  'Extend 7 days',
                                                ),
                                                onTap:
                                                    () => _increaseValidity(
                                                      userId,
                                                      7,
                                                    ),
                                              ),
                                              PopupMenuItem(
                                                child: const Text(
                                                  'Extend 30 days',
                                                ),
                                                onTap:
                                                    () => _increaseValidity(
                                                      userId,
                                                      30,
                                                    ),
                                              ),
                                              PopupMenuItem(
                                                child: const Text(
                                                  'Extend 90 days',
                                                ),
                                                onTap:
                                                    () => _increaseValidity(
                                                      userId,
                                                      90,
                                                    ),
                                              ),
                                            ],
                                        child: const Text('Extend Validity'),
                                      )
                                      : const Text('—'),
                                ),
                                DataCell(
                                  isBlocked
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "Blocked ✅",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                      : IconButton(
                                        icon: const Icon(
                                          Icons.block,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await _blockUser(userId);

                                          // ✅ Update Firestore so UI refreshes
                                          await FirebaseFirestore.instance
                                              .collection("users")
                                              .doc(userId)
                                              .update({"isBlocked": true});
                                        },
                                      ),
                                ),
                              ],
                            );
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
