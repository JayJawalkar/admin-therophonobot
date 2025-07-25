import 'package:admin_therophonobot/features/add_banner_images/views/add_banners_images.dart';
import 'package:admin_therophonobot/features/add_category/views/add_categories.dart';
import 'package:admin_therophonobot/features/add_category/widgets/game_form.dart';
import 'package:admin_therophonobot/features/add_games/views/add_game_screen_home.dart';
import 'package:admin_therophonobot/features/add_games/views/add_game_screen_pathway.dart';
import 'package:admin_therophonobot/features/add_games/views/add_game_screen_syllables.dart';
import 'package:admin_therophonobot/features/add_plans/views/add_plans_screen.dart';
import 'package:admin_therophonobot/features/api_keys/views/api_key_screen.dart';
import 'package:admin_therophonobot/features/approve_docotors/views/approve_doctors.dart';
import 'package:admin_therophonobot/features/colors/views/assign_colors_screen.dart';
import 'package:admin_therophonobot/features/home/views/all_users_screen.dart';
import 'package:admin_therophonobot/features/view_games/views/home_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalUsers = 0;
  int premiumUsers = 0;
  int totalDocotrs = 0;
  int totalHomeGames = 0;
  int totalPathwayGames = 0;
  int totalSyllablesGame = 0;

  @override
  void initState() {
    super.initState();
    fetchUserStats();
    fetchDoctor();
    fetchHomeGames();
    fetchPathwayGames();
    fetchSyllablesGames();
  }

  Future<void> fetchUserStats() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final allUsers = snapshot.docs.length;
      final premium =
          snapshot.docs.where((doc) {
            return doc.data().containsKey('isPremium') &&
                doc['isPremium'] == true;
          }).length;

      setState(() {
        totalUsers = allUsers;
        premiumUsers = premium;
      });
    } catch (e) {
      e.toString();
    }
  }

  Future<void> fetchDoctor() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('doctors').get();
      final homeGames = snapshot.docs.length;
      setState(() {
        totalDocotrs = homeGames;
      });
    } catch (e) {
      e.toString();
    }
  }

  Future<void> fetchHomeGames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('home').get();
      final homeGames = snapshot.docs.length;
      setState(() {
        totalHomeGames = homeGames;
      });
    } catch (e) {
      e.toString();
    }
  }

  Future<void> fetchPathwayGames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('pathway').get();
      final paytwayGames = snapshot.docs.length;
      setState(() {
        totalPathwayGames = paytwayGames;
      });
    } catch (e) {
      e.toString();
    }
  }

  Future<void> fetchSyllablesGames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('syllables').get();
      final syllablesGames = snapshot.docs.length;
      setState(() {
        totalSyllablesGame = syllablesGames;
      });
    } catch (e) {
      e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final crossAxisCount =
        screenWidth > 1000
            ? 3
            : screenWidth > 600
            ? 2
            : 1;

    return Scaffold(
      drawer: isMobile ? const Drawer(child: SidebarContent()) : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 300,
              color: const Color(0xFFEFEFEF),
              padding: const EdgeInsets.all(16),
              child: const SidebarContent(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (isMobile)
                          Builder(
                            builder:
                                (context) => IconButton(
                                  icon: const Icon(Icons.menu),
                                  onPressed:
                                      () => Scaffold.of(context).openDrawer(),
                                ),
                          ),
                        const Text(
                          'Welcome Admin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 20,
                      children: [
                        DashboardCard(
                          color: Colors.amber.shade200,
                          title: 'Total Users',
                          value: totalUsers.toString(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllUsersPage(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.red.shade200,
                          title: 'Premium Users',
                          value: premiumUsers.toString(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const AllUsersPage(
                                      showOnlyPremium: true,
                                    ),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.orange.shade500,

                          title: 'Add Game to Home',
                          value: totalHomeGames.toString(),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddHomeGameScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.deepPurple.shade500,

                          title: 'Add Game to Pathway',
                          value: totalPathwayGames.toString(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPathwayGameScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.green.shade500,

                          title: 'Add Game to Syllables',
                          value: totalSyllablesGame.toString(),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddSyllablesGameScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.cyan.shade500,

                          title: 'Add Plans',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPlansScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.brown.shade500,

                          title: 'Add Banner Images',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddBannersImages(),
                              ),
                            );
                          },
                        ),DashboardCard(
                          color: Colors.blueGrey.shade500,

                          title: 'View Home Games',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomeGamesListScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.blue.shade500,

                          title: 'View Apis',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApiKeyScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          color: Colors.red.shade500,

                          title: 'Add Categories',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddCategoryScreen(),
                              ),
                            );
                          },
                        ),DashboardCard(
                          color: Colors.pink.shade500,

                          title: 'Edit Categories',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoriesOverviewScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarContent extends StatelessWidget {
  const SidebarContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  [
        Text(
          'THEROPHONOBOT',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 30),
        Text(
          'Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignColorsScreen()),
            );
          },
          child: Text('Add event color'),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) =>  ApproveTherapistsScreen()),
            );
          },
          child: Text('Approve therapist'),
        ),
        SizedBox(height: 20),
        
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback onTap;
  final Color? color;
  const DashboardCard({
    super.key,
    required this.title,
    this.value,
    required this.onTap, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color??Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(value!, style: const TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }
}
