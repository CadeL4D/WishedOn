import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'login_screen.dart'; // To navigate out if group deleted

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;
  
  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  // Dialog to fetch members and select one
  Future<void> _showMemberSelectionDialog({
    required String title,
    required Function(String memberId, String memberName) onSelected,
  }) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getGroupMembersStream(widget.groupId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text('No members found.');
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final memberName = data['name'] ?? 'Unknown';
                    return ListTile(
                      title: Text(memberName),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(docs[index].id, memberName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleResetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All List Items'),
        content: const Text('Are you sure you want to clear EVERY member\'s wishlist in this group? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      )
    );

    if (confirm == true) {
      await _databaseService.resetAllListItems(widget.groupId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All list items have been reset.')));
    }
  }

  Future<void> _handleResetIndividual() async {
    await _showMemberSelectionDialog(
      title: 'Select Member to Reset',
      onSelected: (memberId, memberName) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Reset $memberName\'s List'),
            content: Text('Are you sure you want to clear $memberName\'s wishlist?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          )
        );

        if (confirm == true) {
          await _databaseService.resetMemberWishlist(widget.groupId, memberId);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$memberName\'s list has been reset.')));
        }
      }
    );
  }

  Future<void> _handleResetPin() async {
    await _showMemberSelectionDialog(
      title: 'Select Member to Reset PIN',
      onSelected: (memberId, memberName) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Reset $memberName\'s PIN'),
            content: Text('Are you sure you want to reset $memberName\'s PIN? They will be prompted to create a new one the next time they join.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset PIN'),
              ),
            ],
          )
        );

        if (confirm == true) {
          await _databaseService.resetMemberPin(widget.groupId, memberId, '');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$memberName\'s PIN has been reset.')));
        }
      }
    );
  }

  Future<void> _handleDeleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you absolutely sure you want to delete this group FOREVER? All members and wishlists will be destroyed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Group'),
          ),
        ],
      )
    );

    if (confirm == true) {
      await _databaseService.deleteGroup(widget.groupId);
      // Clear preferences and go to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeGroupId');
      await prefs.remove('activeMemberId');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Group Settings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Owner Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Reset All List Items',
            subtitle: 'Clear every member\'s wishlist in this group',
            icon: Icons.clear_all,
            iconColor: Colors.orange,
            onTap: _handleResetAll,
          ),
          _SettingsTile(
            title: 'Reset Individual List Items',
            subtitle: 'Clear the wishlist of a specific member',
            icon: Icons.person_remove,
            iconColor: Colors.amber,
            onTap: _handleResetIndividual,
          ),
          _SettingsTile(
            title: 'Reset Member PIN',
            subtitle: 'Clear a member\'s PIN so they can create a new one',
            icon: Icons.pin_outlined,
            iconColor: Colors.blue,
            onTap: _handleResetPin,
          ),
          _RemoveMemberDropdownTile(
            groupId: widget.groupId,
            databaseService: _databaseService,
          ),
          const SizedBox(height: 30),
          _SettingsTile(
            title: 'Delete Group',
            subtitle: 'Permanently delete this group and all its data',
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _handleDeleteGroup,
          ),
        ],
      ),
    );
  }
}

class _RemoveMemberDropdownTile extends StatefulWidget {
  final String groupId;
  final DatabaseService databaseService;

  const _RemoveMemberDropdownTile({
    required this.groupId,
    required this.databaseService,
  });

  @override
  State<_RemoveMemberDropdownTile> createState() => _RemoveMemberDropdownTileState();
}

class _RemoveMemberDropdownTileState extends State<_RemoveMemberDropdownTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _handleRemoveMember(BuildContext context, String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $memberName'),
        content: Text('Are you sure you want to remove $memberName from this group? This will permanently delete their wishlist and remove them from the group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await widget.databaseService.removeMember(widget.groupId, memberId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$memberName has been removed.'),
              backgroundColor: const Color(0xFF00C48C),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_remove_alt_1_outlined, color: Colors.red),
            ),
            title: const Text(
              'Remove Member',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: const Text('Remove a member and their wishlist from this group', style: TextStyle(fontSize: 12)),
            trailing: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 0.5).animate(_controller),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
            onTap: _toggleExpanded,
          ),
          AnimatedBuilder(
            animation: _controller.view,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _heightFactor,
                axisAlignment: -1.0,
                child: child,
              );
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.databaseService.getGroupMembersStream(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                  );
                }

                final allMembers = snapshot.data?.docs ?? [];
                // Filter out the registered owner (cannot remove themselves)
                final members = allMembers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isRegisteredOwner'] != true;
                }).toList();

                if (members.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      'No other members in this group.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown Member';
                    final emoji = data['emoji'] as String?;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF5D5FEF).withValues(alpha: 0.1),
                          child: Text(
                            (emoji != null && emoji.isNotEmpty)
                                ? emoji
                                : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            style: TextStyle(
                              color: const Color(0xFF5D5FEF),
                              fontWeight: FontWeight.bold,
                              fontSize: (emoji != null && emoji.isNotEmpty) ? 20 : 14,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _handleRemoveMember(context, doc.id, name),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: textColor ?? Colors.black87
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

