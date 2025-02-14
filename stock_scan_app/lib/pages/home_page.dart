import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/category_provider.dart';
import 'auth_page.dart';
import 'inventory_page.dart';
//import 'scan_page.dart';
import 'storage_settings_page.dart';
import 'category_settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      final userId = user.id;
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      storageProvider.fetchStorages(userId);
      categoryProvider.fetchAllCategories();
      categoryProvider.fetchUserCategories(userId);
    }
  }

  Future<void> _signOut() async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Storages'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_outlined),
            onPressed: _signOut,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showSettingsMenu(context);
            },
          ),
        ],
      ),
      body: _screens()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _screens() => [
        InventoryPage(),
        //ScanPage(),
      ];

  Future<dynamic> showSettingsMenu(BuildContext context) {
    return showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.storage),
            title: Text('Storages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StorageSettingsPage(
                    storages: Provider.of<StorageProvider>(context, listen: false).storages,
                    sampleIcons: {}, // Pass your sample icons here
                    onStoragesUpdated: (updatedStorages) {
                      Provider.of<StorageProvider>(context, listen: false).fetchStorages(
                        Provider.of<AuthProvider>(context, listen: false).user!.id,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.category),
            title: Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategorySettingsPage(
                    userCategories: Provider.of<CategoryProvider>(context, listen: false).userCategories,
                    onCategoriesUpdated: (updatedCategories) {
                      Provider.of<CategoryProvider>(context, listen: false).fetchUserCategories(
                        Provider.of<AuthProvider>(context, listen: false).user!.id,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
