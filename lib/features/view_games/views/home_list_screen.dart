import 'package:admin_therophonobot/features/add_games/views/add_game_screen_home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeGamesListScreen extends StatefulWidget {
  @override
  State<HomeGamesListScreen> createState() => _HomeGamesListScreenState();
}

class _HomeGamesListScreenState extends State<HomeGamesListScreen> {
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeGames();
  }

  Future<void> _loadHomeGames() async {
    try {
      final response = await Supabase.instance.client
          .from('games')
          .select('*')
          .eq('category', 'home')
          .order('name', ascending: true);

      setState(() {
        _games = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _errorMessage = null;
      });
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = 'Error loading games: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load games: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGame(String gameId, String gameName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Game'),
            content: Text(
              'Are you sure you want to delete "$gameName"? This will also delete all associated game items.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // First delete game items
        await Supabase.instance.client
            .from('game_items')
            .delete()
            .eq('game_id', gameId);

        // Then delete the game
        await Supabase.instance.client.from('games').delete().eq('id', gameId);

        await _loadHomeGames();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$gameName" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on PostgrestException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting game: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting game: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Home Games')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHomeGames,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : _games.isEmpty
                ? const Center(child: Text('No games found.'))
                : _buildDataTable(context),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
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
            _games.map((game) {
              return DataRow(
                cells: [
                  DataCell(
                    game['banner_url'] != null
                        ? Image.network(
                          game['banner_url'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 40);
                          },
                        )
                        : const Icon(Icons.image, size: 40),
                  ),
                  DataCell(Text(game['name'] ?? 'N/A')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddGameScreen(category: 'home'),
                              ),
                            ).then((_) => _loadHomeGames());
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed:
                              () => _deleteGame(game['id'], game['name']),
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
