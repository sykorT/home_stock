import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_scan_app/pages/scan_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/storage_provider.dart';
import '../providers/category_provider.dart';
import 'inventory_page.dart';
import 'storage_settings_page.dart';
import 'category_settings_page.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (user != null) {
      final userId = user!.id;
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      storageProvider.fetchStorages(userId);
      categoryProvider.fetchAllCategories();
      categoryProvider.fetchUserCategories(userId);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    //await Provider.of<AuthProvider>(context, listen: false).signOut();
    /*Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );*/
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
        selectedItemColor: Colors.teal[800],
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _initializeData();
    });
  }

  List<Widget> _screens() => [
        InventoryPage(),
        ScanPage(),
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
                    sampleIcons: Provider.of<StorageProvider>(context, listen: false).homeStorageIcons,
                    onStoragesUpdated: (updatedStorages) {
                      Provider.of<StorageProvider>(context, listen: false).fetchStorages(
                        user!.id,
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
                        user!.id,
                      );
                      Provider.of<CategoryProvider>(context, listen: false).fetchAllCategories();
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
