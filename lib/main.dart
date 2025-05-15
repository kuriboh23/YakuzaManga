import 'package:flutter/material.dart';
import 'package:yakuza/providers/collection_provider.dart';
import 'package:yakuza/screens/my_collection_screen.dart';
import 'package:yakuza/screens/search_screen.dart';
import 'package:provider/provider.dart';

// LEARN: The main() function is the entry point of the Flutter application.
void main() {
  // LEARN: runApp() inflates the given widget and attaches it to the screen.
  // It's essential to wrap your app with any top-level providers here.
  runApp(
    // LEARN: ChangeNotifierProvider creates an instance of a ChangeNotifier (CollectionProvider)
    // and makes it available to all descendant widgets.
    // `create: (_) => CollectionProvider()` is called lazily the first time the provider is accessed.
    ChangeNotifierProvider(
      create: (_) => CollectionProvider(),
      child: const MangaCollectorApp(),
    ),
  );
}

// LEARN: This is the root widget of your application.
// It's typically a StatelessWidget or StatefulWidget that defines the MaterialApp.
class MangaCollectorApp extends StatelessWidget {
  const MangaCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // LEARN: MaterialApp is a convenience widget that wraps a number of widgets
    // that are commonly required for Material Design applications.
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner in the top right corner
      title: 'Manga Collector',
      // LEARN: Theme.of(context).copyWith allows you to customize the theme.
      // You can define colors, fonts, etc.
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.deepPurple, // A common primary color
        //brightness: Brightness.dark, // Uncomment for a dark theme
        // Or use more detailed color scheme
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            // brightness: Brightness.dark, // Uncomment for dark theme variant of seed
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity, // Adapts to platform density
        appBarTheme: const AppBarTheme(
          elevation: 4.0, // Adds a subtle shadow to app bars
          centerTitle: true,
        ),
        useMaterial3: true, // Enables Material 3 design features
      ),
      // LEARN: `home` defines the default route of the app (the first screen shown).
      // We'll use a BottomNavigationBar, so the home will be a wrapper.
      home: const MainScreen(),
      // LEARN: You can also define named routes for navigation, but for this simple
      // app, direct navigation with MaterialPageRoute is sufficient.
      // routes: {
      //   '/search': (context) => SearchScreen(),
      //   '/collection': (context) => MyCollectionScreen(),
      // },
    );
  }
}

// LEARN: A StatefulWidget to manage the BottomNavigationBar state.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the currently selected tab

  // LEARN: List of widgets to display for each tab.
  static const List<Widget> _widgetOptions = <Widget>[
    SearchScreen(),
    MyCollectionScreen(),
  ];

  // LEARN: Callback function when a tab is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LEARN: The body of the Scaffold displays the widget corresponding to the selected tab.
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // LEARN: BottomNavigationBar provides navigation between top-level views.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'My Collection',
          ),
        ],
        currentIndex: _selectedIndex, // Highlights the current tab
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color for selected item
        onTap: _onItemTapped, // Called when a tab is tapped
      ),
    );
  }
}