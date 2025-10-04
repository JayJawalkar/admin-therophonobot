import 'package:admin_therophonobot/features/home/service/service.dart';
import 'package:flutter/material.dart';

class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Users")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isPremium = user['is_premium'] == true;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user['name'] != null && user['name'].isNotEmpty
                        ? user['name'][0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(user['name'] ?? "Unknown"),
                subtitle: Text(user['email'] ?? "No email"),
                trailing:
                    isPremium
                        ? const Icon(Icons.diamond, color: Colors.blue)
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
class WordCountScreen extends StatelessWidget {
  const WordCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Word Count & User Analytics"),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;
          return WordCountTable(users: users);
        },
      ),
    );
  }
}

class WordCountTable extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const WordCountTable({super.key, required this.users});

  @override
  State<WordCountTable> createState() => _WordCountTableState();
}

class _WordCountTableState extends State<WordCountTable> {
  List<Map<String, dynamic>> get filteredUsers {
    switch (_currentFilter) {
      case UserFilter.all:
        return widget.users;
      case UserFilter.premium:
        return widget.users.where((user) => user['is_premium'] == true).toList();
      case UserFilter.expiring:
        // This would need additional logic for expiring premium
        return widget.users.where((user) => user['is_premium'] == true).toList();
      case UserFilter.blocked:
        return widget.users.where((user) => user['is_blocked'] == true).toList();
      case UserFilter.therapists:
        return widget.users.where((user) => user['is_therapist'] == true).toList();
    }
  }

  UserFilter _currentFilter = UserFilter.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chip Row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            children: UserFilter.values.map((filter) {
              return FilterChip(
                label: Text(filter.label),
                selected: _currentFilter == filter,
                onSelected: (bool selected) {
                  setState(() {
                    _currentFilter = selected ? filter : UserFilter.all;
                  });
                },
              );
            }).toList(),
          ),
        ),

        // Statistics Cards
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildStatCard(
                'Total Users',
                widget.users.length.toString(),
                Colors.blue,
              ),
              _buildStatCard(
                'Premium Users',
                widget.users.where((user) => user['is_premium'] == true).length.toString(),
                Colors.amber,
              ),
              _buildStatCard(
                'Blocked Users',
                widget.users.where((user) => user['is_blocked'] == true).length.toString(),
                Colors.red,
              ),
              _buildStatCard(
                'Therapists',
                widget.users.where((user) => user['is_therapist'] == true).length.toString(),
                Colors.green,
              ),
            ],
          ),
        ),

        // Data Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 16.0,
                headingRowColor: MaterialStateProperty.resolveWith(
                  (states) => Colors.grey[200],
                ),
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Status'), numeric: true),
                  DataColumn(label: Text('Word Usage'), numeric: true),
                  DataColumn(label: Text('Premium'), numeric: true),
                  DataColumn(label: Text('Created'), numeric: true),
                  DataColumn(label: Text('Actions'), numeric: true),
                ],
                rows: filteredUsers.map((user) => _buildDataRow(user)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> user) {
    final wordsUsed = user['words_used'] ?? 0;
    final wordLimit = user['word_limit'] ?? 10;
    final wordCount = user['word_count'] ?? 0;
    final isPremium = user['is_premium'] == true;
    final isBlocked = user['is_blocked'] == true;
    final isTherapist = user['is_therapist'] == true;
    final premiumExpires = user['premium_expires_at'];
    final createdAt = user['created_at'];

    return DataRow(
      cells: [
        // User Cell
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  user['name'] != null && user['name'].isNotEmpty
                      ? user['name'][0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isTherapist)
                    const Text(
                      'Therapist',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Email Cell
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              user['email'] ?? 'No email',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Status Cell
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBlocked ? Icons.block : Icons.check_circle,
                    color: isBlocked ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(isBlocked ? 'Blocked' : 'Active'),
                ],
              ),
              if (isBlocked)
                const Text(
                  'Blocked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),

        // Word Usage Cell
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Used: $wordsUsed/$wordLimit'),
              LinearProgressIndicator(
                value: wordLimit > 0 ? wordsUsed / wordLimit : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  wordsUsed >= wordLimit ? Colors.red : Colors.blue,
                ),
              ),
              Text('Total: $wordCount words'),
            ],
          ),
        ),

        // Premium Cell
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPremium ? Icons.diamond : Icons.diamond_outlined,
                    color: isPremium ? Colors.blue : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(isPremium ? 'Premium' : 'Free'),
                ],
              ),
              if (premiumExpires != null)
                Text(
                  'Exp: ${_formatDate(premiumExpires)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isExpiringSoon(premiumExpires) ? Colors.orange : Colors.grey,
                  ),
                ),
            ],
          ),
        ),

        // Created Cell
        DataCell(Text(_formatDate(createdAt))),

        // Actions Cell
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Block/Unblock
              IconButton(
                icon: Icon(
                  isBlocked ? Icons.lock_open : Icons.block,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                onPressed: () => _toggleBlockUser(user['id'], isBlocked),
                tooltip: isBlocked ? 'Unblock User' : 'Block User',
              ),

              // Extend Premium
              if (isPremium)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_time),
                  tooltip: 'Extend Premium',
                  onSelected: (value) => _extendPremium(user['id'], int.parse(value)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: '7', child: Text('7 days')),
                    const PopupMenuItem(value: '30', child: Text('30 days')),
                    const PopupMenuItem(value: '90', child: Text('90 days')),
                  ],
                ),

              // View Details
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _showUserDetails(user),
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid';
    }
  }

  bool _isExpiringSoon(String premiumExpiresAt) {
    try {
      final expiry = DateTime.parse(premiumExpiresAt);
      final now = DateTime.now();
      final difference = expiry.difference(now);
      return difference.inDays <= 7 && difference.inDays >= 0;
    } catch (e) {
      return false;
    }
  }

  void _toggleBlockUser(String userId, bool currentlyBlocked) async {
    final result = currentlyBlocked
        ? await SupabaseService.unblockUser(userId)
        : await SupabaseService.blockUser(userId);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      // Refresh the screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WordCountScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}')),
      );
    }
  }

  void _extendPremium(String userId, int days) async {
    final result = await SupabaseService.increasePremiumValidity(userId, days);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      // Refresh the screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WordCountScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}')),
      );
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Name', user['name']),
              _buildDetailItem('Email', user['email']),
              _buildDetailItem('Phone', user['phone']),
              _buildDetailItem('Premium', user['is_premium']?.toString()),
              _buildDetailItem('Blocked', user['is_blocked']?.toString()),
              _buildDetailItem('Therapist', user['is_therapist']?.toString()),
              _buildDetailItem('Words Used', user['words_used']?.toString()),
              _buildDetailItem('Word Limit', user['word_limit']?.toString()),
              _buildDetailItem('Word Count', user['word_count']?.toString()),
              _buildDetailItem('Premium Expires', user['premium_expires_at']),
              _buildDetailItem('Created At', user['created_at']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}

enum UserFilter {
  all('All Users'),
  premium('Premium'),
  expiring('Expiring Soon'),
  blocked('Blocked'),
  therapists('Therapists');

  const UserFilter(this.label);
  final String label;
}