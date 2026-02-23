import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/destination.dart';
import '../widgets/category_icon.dart';
import '../widgets/destination_card.dart';
import 'detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedIndex = 0;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.menu, size: 30),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Title
                const Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Tabs
                Row(
                  children: [
                    _buildTab('Places', true),
                    const SizedBox(width: 20),
                    _buildTab('Inspiration', false),
                    const SizedBox(width: 20),
                    _buildTab('Emotions', false),
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
                // Explore more section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore more',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Categories
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: categories.map((cat) => CategoryIcon(category: cat)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Column(
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
        if (isSelected)
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF5D5FEF),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
