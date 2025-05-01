import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../screens/dev_settings_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> heartedRecipes;
  final Map<String, List<Map<String, dynamic>>> customLists;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key, 
    required this.heartedRecipes,
    required this.customLists,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _createNewList(BuildContext context) async {
    final TextEditingController listNameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Create New List',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: listNameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter list name',
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lexend(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final listName = listNameController.text.trim();
              if (listName.isEmpty) return;
              
              try {
                final userId = context.read<AuthProvider>().phoneNumber;
                if (userId == null) return;
                
                final newList = await SupabaseService.createCustomList(
                  userId: userId,
                  listName: listName,
                );
                
                setState(() {
                  if (widget.customLists[listName] == null) {
                    widget.customLists[listName] = [];
                  }
                });
                
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('List "$listName" created successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create list: $e')),
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              'Create',
              style: GoogleFonts.lexend(color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = context.read<AuthProvider>().phoneNumber;
    final userName = context.read<AuthProvider>().userName;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'User',
                          style: GoogleFonts.lexend(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          phoneNumber ?? '',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (kDebugMode)
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevSettingsScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              SizedBox(height: 24),

              // Stats Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Hearted", widget.heartedRecipes.length.toString()),
                    _buildStatItem("Lists", widget.customLists.length.toString()),
                    _buildStatItem("Saved", "0"),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Saved Recipes and Recipe Lists Section with Tabs
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      indicatorColor: Colors.deepOrange,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: "Hearted Recipes"),
                        Tab(text: "Recipe Lists"),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        children: [
                          _buildHeartedRecipesTab(),
                          _buildRecipeListsTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings Section
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text(
                  "Logout",
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: widget.onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildHeartedRecipesTab() {
    return widget.heartedRecipes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Colors.white30,
                ),
                SizedBox(height: 16),
                Text(
                  "No saved recipes yet",
                  style: GoogleFonts.lexend(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Heart recipes to save them here",
                  style: GoogleFonts.lexend(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: widget.heartedRecipes.length,
            itemBuilder: (context, index) {
              var recipe = widget.heartedRecipes[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to recipe details
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(recipe['image_url'] ?? 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['name'] ?? '',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildRecipeListsTab(BuildContext context) {
    return Column(
      children: [
        // Add List Button
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: () => _createNewList(context),
            icon: Icon(Icons.add),
            label: Text(
              'Create New List',
              style: GoogleFonts.lexend(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Lists
        Expanded(
          child: widget.customLists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: Colors.white30,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No recipe lists yet",
                        style: GoogleFonts.lexend(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Create lists to organize your recipes",
                        style: GoogleFonts.lexend(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.customLists.length,
                  itemBuilder: (context, index) {
                    final listName = widget.customLists.keys.elementAt(index);
                    final recipes = widget.customLists[listName] ?? [];
                    return Card(
                      color: Colors.white12,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          listName,
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "${recipes.length} recipes",
                          style: GoogleFonts.lexend(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70),
                        onTap: () {
                          // Navigate to list details
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
