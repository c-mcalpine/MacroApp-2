import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../screens/dev_settings_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? heartedRecipes;
  final Map<String, List<Map<String, dynamic>>>? customLists;
  final VoidCallback? onLogout;

  const ProfileScreen({
    Key? key, 
    this.heartedRecipes,
    this.customLists,
    this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _heartedRecipes = [];
  List<Map<String, dynamic>> _customLists = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final phoneNumber = context.read<AuthProvider>().phoneNumber;
      if (phoneNumber != null) {
        // Use passed parameters if available, otherwise fetch from Supabase
        if (widget.heartedRecipes != null) {
          _heartedRecipes = widget.heartedRecipes!;
        } else {
          final heartedRecipes = await SupabaseService.getHeartedRecipes(phoneNumber);
          _heartedRecipes = heartedRecipes;
        }
        
        if (widget.customLists != null) {
          // Convert the custom lists to the format expected by the UI
          _customLists = widget.customLists!.entries.map((entry) {
            return {
              'name': entry.key,
              'items': entry.value,
            };
          }).toList();
        } else {
          final customLists = await SupabaseService.getCustomLists(phoneNumber);
          _customLists = customLists;
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Logout",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: GoogleFonts.lexend(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.lexend(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Logout",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white70),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _showLogoutConfirmation();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepOrange,
                      child: Text(
                        _userData?['username']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: GoogleFonts.lexend(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _userData?['username'] ?? 'User',
                      style: GoogleFonts.lexend(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

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
                    _buildStatItem("Hearted", _heartedRecipes.length.toString()),
                    _buildStatItem("Lists", _customLists.length.toString()),
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
              Text(
                "Settings",
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingsItem(Icons.notifications, "Notifications"),
              _buildSettingsItem(Icons.lock, "Privacy"),
              _buildSettingsItem(Icons.help, "Help & Support"),
              _buildSettingsItem(Icons.info, "About"),
              _buildSettingsItem(Icons.logout, "Logout", onTap: _showLogoutConfirmation),
              
              // Development Settings (only visible in debug mode)
              if (kDebugMode) ...[
                SizedBox(height: 16),
                _buildSettingsItem(
                  Icons.developer_mode, 
                  "Development Settings", 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DevSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final phoneNumber = context.read<AuthProvider>().phoneNumber;
          if (phoneNumber != null) {
            try {
              await SupabaseService.createCustomList(
                userId: phoneNumber,
                listName: 'New List',
              );
              _loadUserData();
            } catch (e) {
              print('Error creating custom list: $e');
            }
          }
        },
        child: const Icon(Icons.add),
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
        SizedBox(height: 4),
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

  Widget _buildSettingsItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartedRecipesTab() {
    return _heartedRecipes.isEmpty
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
            itemCount: _heartedRecipes.length,
            itemBuilder: (context, index) {
              var recipe = _heartedRecipes[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to recipe details
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(recipe['image_url']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['name'] ?? 'Recipe',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "My Lists",
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _showCreateListDialog(context);
              },
              icon: Icon(Icons.add, color: Colors.deepOrange, size: 18),
              label: Text(
                "New List",
                style: GoogleFonts.lexend(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _customLists.isEmpty
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
                      "No custom lists yet",
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
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _customLists.length,
                itemBuilder: (context, index) {
                  final list = _customLists[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        list['name'] ?? 'Unnamed List',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${list['items']?.length ?? 0} items',
                        style: GoogleFonts.lexend(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // TODO: Implement delete custom list
                          _loadUserData();
                        },
                      ),
                      onTap: () {
                        // Navigate to list details
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _showCreateListDialog(BuildContext context) {
    String? newListName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Create New List",
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter list name",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              newListName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.lexend(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newListName != null && newListName!.trim().isNotEmpty) {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final trimmedName = newListName!.trim();
                  final phoneNumber = authProvider.phoneNumber;
                  if (phoneNumber != null) {
                    await SupabaseService.createCustomList(
                      userId: phoneNumber,
                      listName: trimmedName,
                    );
                    await _loadUserData(); // Reload data after creating list
                  }
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Create",
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
