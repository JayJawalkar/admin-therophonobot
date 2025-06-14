import 'package:admin_therophonobot/features/add_games/views/add_game_screen_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeGamesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Home Games'),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('home').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final games = snapshot.data!.docs;
            if (games.isEmpty) {
              return Center(child: Text('No games found.'));
            }

            return _buildDataTable(context, games);
          },
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<DocumentSnapshot> games) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: DataTable(
        columnSpacing: 100,
        columns: const [
          DataColumn(label: Text('Banner')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            games.map((game) {
              final data = game.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(
                    data['bannerUrl'] != null
                        ? Image.network(
                          data['bannerUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, size: 40);
                          },
                        )
                        : Icon(Icons.image, size: 40),
                  ),
                  DataCell(Text(data['name'] ?? 'N/A')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddHomeGameScreen(
                                      gameData: game,
                                      documentId: game.id,
                                    ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('home')
                                .doc(game.id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
