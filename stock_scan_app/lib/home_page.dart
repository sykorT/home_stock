import 'package:flutter/material.dart';
import 'package:stock_scan_app/auth_page.dart';
import 'package:stock_scan_app/category_settings_page.dart';
import 'package:stock_scan_app/models/category.dart';
import 'package:stock_scan_app/models/inventory_item.dart';
import 'package:stock_scan_app/models/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stock_scan_app/inventory_page.dart';
import 'package:stock_scan_app/scan_page.dart';
import 'package:stock_scan_app/storage_settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  // Index of the currently selected screen (0 = Inventory, 1 = Scan)
  int _selectedIndex = 0;
  // List of storages
  List<Storage> _storages = [];
  List<Category> _allCategories = [];
  List<Category> _userCategories = [];

  // Dictionary of sample icons for storages
  final Map<int, IconData> _sampleIcons = {
    1: Icons.kitchen,
    2: Icons.ac_unit,
    3: Icons.store,
    4: Icons.pets,
    5: Icons.home,
    6: Icons.shopping_cart,
    7: Icons.badge_sharp,
    8: Icons.local_florist,
    9: Icons.local_drink,
    10: Icons.local_bar,
    11: Icons.local_cafe,
    12: Icons.fastfood,
    13: Icons.gif_box,
  };

  @override
  void initState() {
    super.initState();
    _fetchDataFromDB();
  }

  // Function to sign out the user
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    }
  }

  // Function to fetch storages and items from Supabase
  Future<void> _fetchDataFromDB() async {

    await _fetchAllCategories();
    await _fetchUserCategories();

    final storagesResponse = await supabase
        .from('storages')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id);

    List<Storage> storages = [];

    for (var storage in storagesResponse) {
      final itemsResponse = await supabase
          .from('storage_summary')
          .select('storage_id, total_quantity, item_category, normalized_item_name')
          .eq('storage_id', storage['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('normalized_item_name', ascending: true);

      final items = itemsResponse.map((item) {
        return InventoryItem(
          storageID: item['storage_id'],
          productName: item['normalized_item_name'],
          quantity: item['total_quantity'],
          category: item['item_category'],
        );
      }).toList();

      storages.add(Storage(
        id: storage['id'],
        name: storage['name'],
        items: items,
        iconId: storage['icon_id'],
      ));
    }

    setState(() {
      _storages = storages;
    });
  }


  Future<void> _fetchAllCategories() async {
    final categoriesResponse = await supabase
      .from('categories')
      .select()
      .or('user_id.eq.${supabase.auth.currentUser!.id},user_id.is.null');
    
    List<Category> categories = categoriesResponse.map((category) {
      return Category(
      id: category['id'],
      name: category['name'],
      );
    }).toList();
    
    setState(() {
      _allCategories = categories;
    });
  }

  Future<void> _fetchUserCategories() async {
    final categoriesResponse = await Supabase.instance.client
      .from('categories')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id);
    
    List<Category> categories = categoriesResponse.map((category) {
      return Category(
        id: category['id'],
        name: category['name'],
      );
    }).toList();
    
    setState(() {
      _userCategories = categories;
    });
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

  // Function to switch between screens in the bottom menu
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Returns a list of screens (in our case 2 screens)
  List<Widget> _screens() => [
        InventoryPage(storages: _storages, sampleIcons: _sampleIcons, categories: _allCategories),
        ScanPage(storages: _storages, categories: _allCategories, fetchDataFromDB: _fetchDataFromDB),
      ];

  // Function to show settings menu
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
                    storages: _storages,
                    sampleIcons: _sampleIcons,
                    onStoragesUpdated: (updatedStorages) {
                      setState(() {
                        _storages = updatedStorages;
                      });
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
                    userCategories: _userCategories,
                    onCategoriesUpdated: (updatedCategories) {
                      setState(() {
                        _userCategories = updatedCategories;
                        _fetchAllCategories(); 
                      });
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

