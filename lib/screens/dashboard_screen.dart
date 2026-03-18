import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/database_service.dart';
import 'wishlists_screen.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userId = user?.uid;
    });
  }

  Future<void> _joinExistingGroup(String groupId, String ownerUid) async {
    if (_userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeGroupId', groupId);

    print('[WishOnIt] _joinExistingGroup: userId=$_userId ownerUid=$ownerUid groupId=$groupId');

    String activeMemberId = '';
    
    try {
      // Step 1: Check if the user has a direct member doc (i.e. they are the owner)
      final ownerDocRef = FirebaseFirestore.instance
          .collection('groups').doc(groupId)
          .collection('members').doc(_userId);
      final ownerDocSnap = await ownerDocRef.get();
      
      if (ownerDocSnap.exists) {
        // User IS the owner or was added directly with their UID as document ID
        print('[WishOnIt] Found direct member doc -> activeMemberId=$_userId (owner)');
        activeMemberId = _userId!;
      } else {
        // Step 2: Search for a guest profile they claimed (must NOT be the owner's profile)
        final qs = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .where('claimedByUid', isEqualTo: _userId)
            .get();
        
        for (final doc in qs.docs) {
          final docData = doc.data() as Map<String, dynamic>;
          final isOwnerDoc = doc.id == ownerUid || docData['isRegisteredOwner'] == true;
          
          if (!isOwnerDoc) {
            // Valid claimed profile
            print('[WishOnIt] Found claimed guest profile -> activeMemberId=${doc.id}');
            activeMemberId = doc.id;
            break;
          } else {
            // Bad state: they've incorrectly claimed the owner's profile. Self-heal.
            print('[WishOnIt] Removing bad claimedByUid from owner doc: ${doc.id}');
            try {
              await doc.reference.update({'claimedByUid': FieldValue.delete()});
            } catch (e) {
              print('[WishOnIt] Error self-healing: $e');
            }
          }
        }
        // If activeMemberId is still '', they join as a viewer (no My List tab)
      }
    } catch (e) {
      print('Error finding member: $e');
    }

    print('[WishOnIt] Final activeMemberId=$activeMemberId isOwner=${_userId == ownerUid}');

    await prefs.setString('activeMemberId', activeMemberId);
    if (activeMemberId.isEmpty) {
      await prefs.remove('activeMemberId');
    }

    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WishlistsScreen(
            isOwner: _userId != null && ownerUid == _userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('My Groups'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              try {
                await GoogleSignIn().disconnect();
              } catch (e) {
                print("Error disconnecting Google: $e");
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('activeGroupId');
              await prefs.remove('activeMemberId');
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'My Groups',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _databaseService.getUserGroupsStream(_userId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Center(child: Text("Error: ${snapshot.error}")),
                          );
                        }

                        final groups = snapshot.data?.docs ?? [];

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < groups.length) {
                                  final doc = groups[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  return _buildGroupCard(
                                    name: data['name'] ?? 'Unknown Group',
                                    ownerUid: data['ownerUid'] ?? '',
                                    joinCode: data['joinCode'] ?? '',
                                    onTap: () => _joinExistingGroup(doc.id, data['ownerUid']),
                                  );
                                } else {
                                  return _buildAddGroupCard(context);
                                }
                              },
                              childCount: groups.length + 1, // Add 1 for the Add button
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGroupCard({
    required String name,
    required String ownerUid,
    required String joinCode,
    required VoidCallback onTap,
  }) {
    final isOwner = _userId != null && ownerUid == _userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D5FEF).withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFF5D5FEF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwner ? 'Owner • Code: $joinCode' : 'Member',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5D5FEF).withOpacity(0.05),
                  border: Border.all(color: const Color(0xFF5D5FEF).withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF5D5FEF),
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create Group',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5D5FEF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinGroupScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C).withOpacity(0.05),
                  border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_add_outlined,
                      color: Color(0xFF00C48C),
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Join Group',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00C48C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
