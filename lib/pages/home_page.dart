import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'book_spot_page.dart';
import 'list_spot_page.dart';
import 'listing_history_page.dart';
import 'booking_history_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String> _getUserName(User user) async {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'User';
      }
    } catch (e) {
      // Log error or handle appropriately
      // print("Error fetching user name: $e");
    }
    return 'User';
  }

  Widget _buildHomeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        minimumSize: const Size(double.infinity, 60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Manager'),
        actions: [
          // Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // Add a drawer for navigation options
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.teal,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Parking Manager',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  if (user != null)
                    FutureBuilder<String>(
                      future: _getUserName(user),
                      builder: (context, snapshot) {
                        String name = snapshot.data ?? 'User';
                        return Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Book a Spot'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BookSpotPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('List a New Spot'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ListSpotPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: const Text('My Listed Spots'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListingHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('My Booking History'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                FutureBuilder<String>(
                  future: _getUserName(user),
                  builder: (context, snapshot) {
                    String welcomeName = 'User';
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      welcomeName = 'Loading...';
                    } else if (snapshot.hasData) {
                      welcomeName = snapshot.data!;
                    } else if (snapshot.hasError) {
                      welcomeName = 'User (Error)';
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Welcome, $welcomeName!',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHomeButton(
                          context,
                          icon: Icons.search_outlined,
                          label: 'Book a Parking Spot',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const BookSpotPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePageAlt extends StatelessWidget {
  const HomePageAlt({super.key});

  Future<String> _getUserName(User user) async {
    // Try Firebase Auth display name first
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Fallback to Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'User';
      }
    } catch (e) {
      // Log error or handle
    }
    return 'User'; // Default if not found
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Manager Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // Removed stray parenthesis and semicolon here
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                FutureBuilder<String>(
                  future: _getUserName(user),
                  builder: (context, snapshot) {
                    String welcomeName = 'User';
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      welcomeName = snapshot.data!;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Welcome, $welcomeName!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.teal[800]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    // Added for smaller screens
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHomeButton(
                          context,
                          icon: Icons.search,
                          label: 'Book a Parking Spot',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const BookSpotPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHomeButton(
                          context,
                          icon: Icons.add_location_alt_outlined,
                          label: 'List a New Spot',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ListSpotPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHomeButton(
                          context,
                          icon: Icons.history_edu_outlined,
                          label: 'My Listed Spots',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ListingHistoryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHomeButton(
                          context,
                          icon: Icons.receipt_long_outlined,
                          label: 'My Booking History',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BookingHistoryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60), // Make buttons wider
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}
