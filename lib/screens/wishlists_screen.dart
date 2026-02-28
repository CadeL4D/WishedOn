import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/my_list_item.dart';
import '../widgets/person_card.dart';
import 'person_wishlist_screen.dart';
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

  final List<Person> groupMembers = [
    Person(
      id: '1',
      name: 'Sarah (Me)',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
      wishlist: [], // Usually fetched from the local prefs or DB
    ),
    Person(
      id: '2',
      name: 'John Doe',
      avatarUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200&auto=format&fit=crop',
      wishlist: [
        MyListItem(id: 'a', name: 'AirPods Pro', price: 249.0, url: 'https://apple.com', domain: 'apple.com'),
        MyListItem(id: 'b', name: 'Standing Desk', price: 399.0, url: 'https://ikea.com', domain: 'ikea.com'),
      ],
    ),
    Person(
      id: '3',
      name: 'Alice',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200&auto=format&fit=crop',
      wishlist: [
        MyListItem(id: 'c', name: 'Kindle Paperwhite', price: 139.0, url: 'https://amazon.com', domain: 'amazon.com'),
      ],
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
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupMembers.length,
                  itemBuilder: (context, index) {
                    return PersonCard(
                      person: groupMembers[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonWishlistScreen(
                              person: groupMembers[index],
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
