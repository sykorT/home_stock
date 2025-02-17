import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:stock_scan_app/pages/auth_gate.dart';
import 'package:stock_scan_app/providers/storage_provider.dart';
import 'package:stock_scan_app/providers/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // Initialize Supabase with URL and anon key
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()), 
        // ...other providers if any...
      ],
      child: MaterialApp(
        title: 'Home Storage',
        theme: appUserTheme(),
        home: AuthGate(),
      ),
    );
  }
}

/// Define the theme for the application
ThemeData appUserTheme() {
  return ThemeData(
    primaryColor: Colors.teal[900],
    iconTheme: IconThemeData(color: Colors.teal[900]), // Set icon color
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.teal[900], fontSize: 20, fontWeight: FontWeight.bold,),
      bodyMedium: TextStyle(color:  Colors.grey[900], fontSize: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.teal[900]),
      hintStyle: TextStyle(color: Colors.teal[900]),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.teal[900] ?? Colors.teal),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.teal[900] ?? Colors.teal),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.teal[900], // Set cursor color
      selectionColor: Colors.teal[200], // Color for selected text
      selectionHandleColor: Colors.teal[900], // Color of selection handles
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.teal[900], // Text color
        backgroundColor: Colors.grey[100], // Background color
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    elevatedButtonTheme:  ElevatedButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.teal[900], // Text color
        backgroundColor: Colors.grey[300], // Background color
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 35),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.teal[900],
      iconColor: Colors.teal[900],
      selectedColor: Colors.teal[900],
      selectedTileColor: Colors.teal[050],
      ),
      iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: MaterialStateProperty.all(Colors.teal[900]),
      ),
    ),
    appBarTheme: AppBarTheme(
      color: Colors.teal,
    ),
  );
}

