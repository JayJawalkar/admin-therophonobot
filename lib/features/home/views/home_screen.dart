import 'package:admin_therophonobot/features/add_banner_images/views/add_banners_images.dart';
import 'package:admin_therophonobot/features/add_category/views/add_categories.dart';
import 'package:admin_therophonobot/features/add_category/views/categories_overview_screen.dart';
import 'package:admin_therophonobot/features/add_games/views/add_game_screen_home.dart';
import 'package:admin_therophonobot/features/add_games/views/add_game_screen_syllables.dart';
import 'package:admin_therophonobot/features/add_plans/views/add_plans_screen.dart';
import 'package:admin_therophonobot/features/api_keys/views/api_key_screen.dart';
import 'package:admin_therophonobot/features/approve_docotors/views/approve_doctors.dart';
import 'package:admin_therophonobot/features/colors/views/assign_colors_screen.dart';
import 'package:admin_therophonobot/features/home/views/all_users_screen.dart';
import 'package:admin_therophonobot/features/view_games/views/home_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalUsers = 0;
  int premiumUsers = 0;
  int totalDoctors = 0;
  int totalHomeGames = 0;
  int totalPathwayGames = 0;
  int totalSyllablesGame = 0;
  int totalCategories = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final categories = await Supabase.instance.client
          .from('categories')
          .select('id');

      // Add your other data loading calls here
      // final users = await Supabase.instance.client.from('users').select('id');
      // etc...

      setState(() {
        totalCategories = categories.length;
        // Set other counts from your API calls
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const AppDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) const AppDrawer(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(isMobile, context),

                  const SizedBox(height: 32),

                  // Quick Actions Title
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dashboard Grid
                  Expanded(child: _buildDashboardGrid(isMobile)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.deepPurple),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back, Admin!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your platform efficiently',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Users', '1,234', Icons.people, Colors.blue),
          _buildStatCard(
            'Premium Users',
            '456',
            Icons.workspace_premium,
            Colors.amber,
          ),
          _buildStatCard(
            'Therapists',
            '89',
            Icons.medical_services,
            Colors.green,
          ),
          _buildStatCard(
            'Categories',
            '$totalCategories',
            Icons.category,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDashboardGrid(bool isMobile) {
    final crossAxisCount = isMobile ? 2 : 3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.2,
      children: [
        _buildDashboardCard(
          'User Management',
          Icons.people,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WordCountScreen()),
          ),
        ),
        _buildDashboardCard(
          'Add Home Game',
          Icons.home,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddGameScreen(category: 'home')),
          ),
        ),
        _buildDashboardCard(
          'Add Pathway Game',
          Icons.flag,
          Colors.deepPurple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddGameScreen(category: 'pathway'),
            ),
          ),
        ),
        _buildDashboardCard(
          'Add Syllables Game',
          Icons.text_fields,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddSyllablesGameScreen()),
          ),
        ),
        _buildDashboardCard(
          'Manage Plans',
          Icons.assignment,
          Colors.cyan,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPlansScreen()),
          ),
        ),
        _buildDashboardCard(
          'Banner Images',
          Icons.image,
          Colors.brown,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddBannersImages()),
          ),
        ),
        _buildDashboardCard(
          'View Games',
          Icons.view_list,
          Colors.blueGrey,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomeGamesListScreen()),
          ),
        ),
        _buildDashboardCard(
          'API Keys',
          Icons.vpn_key,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApiKeyScreen()),
          ),
        ),
        _buildDashboardCard(
          'Add Categories',
          Icons.add_box,
          Colors.red,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCategoryScreen()),
          ),
        ),
        _buildDashboardCard(
          'Edit Categories',
          Icons.edit,
          Colors.pink,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoriesOverviewScreen()),
          ),
        ),
        _buildDashboardCard(
          'Event Colors',
          Icons.color_lens,
          Colors.teal,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignColorsScreen()),
          ),
        ),
        _buildDashboardCard(
          'Approve Therapists',
          Icons.verified,
          Colors.indigo,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApproveTherapistsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepPurple.shade700, Colors.purple.shade600],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.psychology,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'THEROPHONOBOT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDrawerItem(
                  Icons.dashboard,
                  'Dashboard',
                  () => Navigator.of(context).pop(),
                  isSelected: true,
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.color_lens,
                  'Event Colors',
                  () => _navigateTo(context, const AssignColorsScreen()),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.verified,
                  'Approve Therapists',
                  () => _navigateTo(context, ApproveTherapistsScreen()),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.settings,
                  'System Settings',
                  () {}, // Add your settings screen
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.analytics,
                  'Analytics',
                  () {}, // Add your analytics screen
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.help,
                  'Help & Support',
                  () {}, // Add your help screen
                ),
              ],
            ),
          ),

          // Footer
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepPurple : Colors.black87,
        ),
      ),
      tileColor: isSelected ? Colors.deepPurple.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
