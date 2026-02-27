import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';
import 'detail_screen.dart';
import 'group_settings_screen.dart';
import 'my_list_screen.dart';

class WishlistsScreen extends StatefulWidget {
  final bool isOwner;

  const WishlistsScreen({super.key, this.isOwner = false});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  int _selectedIndex = 0;
  int _selectedTopTab = 0;

  final List<Destination> destinations = [
    Destination(
      title: 'Cascade',
      location: 'Canada, Banff',
      imageUrl: 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?q=80&w=800&auto=format&fit=crop',
      rating: 4.5,
      price: 180,
      description: 'Cascade Mountain is a mountain located in the Bow River Valley of Banff National Park, Alberta, Canada. The mountain is named for the waterfall or cascade on the southern flanks of the peak.',
    ),
    Destination(
      title: 'Yosemite',
      location: 'USA, California',
      imageUrl: 'https://images.unsplash.com/photo-1426604966848-d7adac402bff?q=80&w=800&auto=format&fit=crop',
      rating: 4.0,
      price: 250,
      description: 'Yosemite National Park is located in central Sierra Nevada in the US state of California. It is located near the wild protected areas.',
    ),
  ];

  final List<Category> categories = [
    Category(
      title: 'Kayaking',
      icon: Icons.kayaking_outlined,
      iconColor: Colors.blueAccent,
    ),
    Category(
      title: 'Snorkeling',
      icon: Icons.scuba_diving_outlined,
      iconColor: Colors.orangeAccent,
    ),
    Category(
      title: 'Ballooning',
      icon: Icons.air,
      iconColor: Colors.purpleAccent,
    ),
    Category(
      title: 'Hiking',
      icon: Icons.hiking_outlined,
      iconColor: Colors.greenAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine the active pages based on role
    final List<Widget> pages = [
      _buildWishlistsContent(),
      const MyListScreen(),
    ];
    
    if (widget.isOwner) {
      pages.add(const GroupSettingsScreen());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_rounded),
        label: 'Wishlists',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.format_list_bulleted),
        label: 'My List',
      ),
    ];

    if (widget.isOwner) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Group Settings',
        ),
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: const Color(0xFF5D5FEF),
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: items,
    );
  }

  Widget _buildWishlistsContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar Area
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.menu, size: 30),
                ],
              ),
              const SizedBox(height: 30),
              // Title
              const Text(
                'Wishlists',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Tabs
              Row(
                children: [
                  _buildTab('All', 0),
                  const SizedBox(width: 20),
                  _buildTab('Bought', 1),
                  const SizedBox(width: 20),
                  _buildTab('Remaining', 2),
                ],
              ),
              const SizedBox(height: 20),
              // Horizontal ListView
              SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    return DestinationCard(
                      destination: destinations[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              destination: destinations[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              // Upcoming section
              const Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Christmas Card (Square with Icon)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7ED), // Light green background
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.park, // Christmas tree-like icon
                        color: Color(0xFF00C48C),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                      'Christmas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _selectedTopTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTopTab = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isSelected
                ? Container(
                    key: const ValueKey('selected'),
                    height: 6,
                    width: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5D5FEF),
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('unselected'),
                    height: 6,
                    width: 6,
                  ),
          ),
        ],
      ),
    );
  }
}
