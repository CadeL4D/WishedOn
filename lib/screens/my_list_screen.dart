import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/my_list_item.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class MyListScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MyListScreen({super.key, this.onBack});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _groupId;
  String? _memberId;
  bool _isLoading = true;
  bool _isOwner = false;
  String _currentEmoji = '😊';

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final gId = prefs.getString('activeGroupId');
    final mId = prefs.getString('activeMemberId');

    if (gId != null && mId != null) {
      try {
        final memberSnap = await FirebaseFirestore.instance
            .collection('groups')
            .doc(gId)
            .collection('members')
            .doc(mId)
            .get();
        if (memberSnap.exists) {
          final data = memberSnap.data()!;
          _isOwner = data['isRegisteredOwner'] ?? false;
          _currentEmoji = data['emoji'] ?? '😊';
        }
      } catch (e) {
        debugPrint('Error loading member info: $e');
      }
    }

    setState(() {
      _groupId = gId;
      _memberId = mId;
      _isLoading = false;
    });
  }

  Future<void> _addItem(MyListItem item) async {
    if (_groupId != null && _memberId != null) {
      await _databaseService.addWishlistItem(_groupId!, _memberId!, item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active group found.')),
      );
    }
  }

  Future<void> _deleteItem(String id) async {
    if (_groupId != null && _memberId != null) {
      await _databaseService.deleteWishlistItem(_groupId!, _memberId!, id);
    }
  }

  Future<void> _updateItem(MyListItem item) async {
    if (_groupId != null && _memberId != null) {
      await _databaseService.updateWishlistItem(_groupId!, _memberId!, item);
    }
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddItemDialog(onAdd: _addItem);
      },
    );
  }

  void _showEditItemDialog(BuildContext context, MyListItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AddItemDialog(
          onAdd: _updateItem,
          existingItem: item,
        );
      },
    );
  }

  String? _getLogoUrl(String domain) {
    const logos = {
      'amazon.com': 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Amazon_icon.svg',
      'target.com': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Target_Corporation_logo_%28vector%29.svg',
      'ulta.com': 'https://s3.amazonaws.com/images.ecwid.com/images/33423725/1483864195.jpg',
      'walmart.com': 'https://upload.wikimedia.org/wikipedia/commons/c/ca/Walmart_logo.svg',
      'bestbuy.com': 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Best_Buy_Logo.svg',
      'sephora.com': 'https://upload.wikimedia.org/wikipedia/commons/4/41/Sephora_logo.svg',
      'etsy.com': 'https://upload.wikimedia.org/wikipedia/commons/8/89/Etsy_logo.svg',
      'ebay.com': 'https://upload.wikimedia.org/wikipedia/commons/1/1b/EBay_logo.svg',
      'homedepot.com': 'https://upload.wikimedia.org/wikipedia/commons/5/5f/TheHomeDepot.svg',
      'ikea.com': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Ikea_logo.svg',
      'shein.com': 'https://upload.wikimedia.org/wikipedia/commons/9/91/SHEIN_LOGO.svg',
      'apple.com': 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
    };
    return logos[domain];
  }

  void _changeEmoji() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) async {
              Navigator.pop(context); // close emoji picker
              Navigator.pop(context); // close settings menu
              
              setState(() {
                _currentEmoji = emoji.emoji;
              });

              if (_groupId != null && _memberId != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(_groupId!)
                      .collection('members')
                      .doc(_memberId!)
                      .update({'emoji': emoji.emoji});
                  
                  // If the user is logged in, also update their master user document
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && _memberId == user.uid) {
                    await _databaseService.updateUserProfile(user.uid, emoji: emoji.emoji);
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emoji updated successfully!'),
                      backgroundColor: Color(0xFF00C48C),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating emoji: $e')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _resetMyList() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Wishlist'),
        content: const Text('Are you sure you want to clear your wishlist? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear List'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirm != true) return;
    if (_groupId == null || _memberId == null) return;

    try {
      await _databaseService.resetMemberWishlist(_groupId!, _memberId!);
      if (!context.mounted) return;
      Navigator.pop(context); // close settings menu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your wishlist has been cleared.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing wishlist: $e')),
      );
    }
  }

  Future<void> _leaveGroup() async {
    if (_isOwner) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Leave Group'),
          content: const Text('As the owner, you cannot leave this group. If you want to disband the group, you can delete it from the Group Settings page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group? Your wishlist and profile will be permanently deleted from the group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirm != true) return;
    if (_groupId == null || _memberId == null) return;

    try {
      await _databaseService.removeMember(_groupId!, _memberId!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeGroupId');
      await prefs.remove('activeMemberId');

      if (!context.mounted) return;
      Navigator.pop(context); // close settings menu
      
      final isSignedIn = FirebaseAuth.instance.currentUser != null;

      if (isSignedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(
              messageToShow: 'You have left the group.',
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'List Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D5FEF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _currentEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: const Text('Change Emoji', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Change the emoji shown on the group menu'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _changeEmoji,
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.clear_all, color: Colors.orange),
                  ),
                  title: const Text('Reset My Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Clear all items from your wishlist'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _resetMyList,
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.exit_to_app, color: Colors.red),
                  ),
                  title: const Text(
                    'Leave Group', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  subtitle: const Text('Delete your wishlist and leave this group'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                  onTap: _leaveGroup,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('My List'),
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_groupId == null || _memberId == null)
              ? const Center(
                  child: Text('No active group joined.'),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: _databaseService.getMemberWishlistStream(_groupId!, _memberId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading wishlist: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'My Personal Saved Items',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    final items = snapshot.data!.docs.map((doc) {
                      return MyListItem.fromJson(doc.data() as Map<String, dynamic>);
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final domain = item.domain ?? '';
                        final logoUrl = _getLogoUrl(domain);

                        return GestureDetector(
                          onTap: () => _showEditItemDialog(context, item),
                          child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: domain.isNotEmpty && logoUrl != null
                                  ? logoUrl.endsWith('.svg')
                                      ? SvgPicture.network(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.network(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.link, color: Colors.grey),
                                        )
                                  : const Icon(Icons.link, color: Colors.grey),
                            ),
                            title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteItem(item.id),
                            ),
                          ),
                        ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class AddItemDialog extends StatefulWidget {
  final Function(MyListItem) onAdd;
  final MyListItem? existingItem;

  const AddItemDialog({super.key, required this.onAdd, this.existingItem});

  bool get isEditing => existingItem != null;

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  String _domain = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.name;
      _priceController.text = widget.existingItem!.price.toStringAsFixed(2);
      _urlController.text = widget.existingItem!.url;
      _domain = widget.existingItem!.domain ?? '';
    }
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      if (_domain.isNotEmpty) setState(() => _domain = '');
      return;
    }

    try {
      Uri? uri = Uri.tryParse(text);
      if (uri != null && uri.host.isNotEmpty) {
        _resolveUrlAndDomain(uri.toString());
      } else if (text.contains('.') && !text.contains(' ')) {
        uri = Uri.tryParse('https://$text');
        if (uri != null && uri.host.isNotEmpty) {
          _resolveUrlAndDomain(uri.toString());
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _resolveUrlAndDomain(String urlString) async {
    try {
      // 1. Try to fetch the URL to resolve redirects
      final response = await http.get(Uri.parse(urlString));
      
      // 2. The response object contains the *final* URL after redirects
      final finalUri = response.request?.url;
      
      if (finalUri != null && finalUri.host.isNotEmpty) {
        final host = _getPrimaryDomain(finalUri.host);
        if (_domain != host && mounted) {
           setState(() => _domain = host);
        }
        return;
      }
    } catch (e) {
      // Ignored: HTTP request failed (maybe CORS, maybe bad network)
    }

    // 3. Fallback: just use the typed domain if fetching failed
    final uri = Uri.tryParse(urlString);
    if (uri != null && uri.host.isNotEmpty) {
      final host = _getPrimaryDomain(uri.host);
      if (_domain != host && mounted) {
         setState(() => _domain = host);
      }
    }
  }

  String _getPrimaryDomain(String host) {
    host = host.toLowerCase();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    const shortLinks = {
      'a.co': 'amazon.com',
      'amzn.to': 'amazon.com',
      'youtu.be': 'youtube.com',
      't.co': 'twitter.com',
      'fb.me': 'facebook.com',
      'ig.me': 'instagram.com',
      'walmrt.us': 'walmart.com',
    };
    
    for (var entry in shortLinks.entries) {
      if (host == entry.key || host.endsWith('.${entry.key}')) {
        return entry.value;
      }
    }
    return host;
  }

  String? _getLogoUrl(String domain) {
    // Map known domains to high-quality direct logo URLs
    const logos = {
      'amazon.com': 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Amazon_icon.svg',
      'target.com': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Target_Corporation_logo_%28vector%29.svg',
      'ulta.com': 'https://s3.amazonaws.com/images.ecwid.com/images/33423725/1483864195.jpg',
      'walmart.com': 'https://upload.wikimedia.org/wikipedia/commons/c/ca/Walmart_logo.svg',
      'bestbuy.com': 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Best_Buy_Logo.svg',
      'sephora.com': 'https://upload.wikimedia.org/wikipedia/commons/4/41/Sephora_logo.svg',
      'etsy.com': 'https://upload.wikimedia.org/wikipedia/commons/8/89/Etsy_logo.svg',
      'ebay.com': 'https://upload.wikimedia.org/wikipedia/commons/1/1b/EBay_logo.svg',
      'homedepot.com': 'https://upload.wikimedia.org/wikipedia/commons/5/5f/TheHomeDepot.svg',
      'ikea.com': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Ikea_logo.svg',
      'shein.com': 'https://upload.wikimedia.org/wikipedia/commons/9/91/SHEIN_LOGO.svg',
      'apple.com': 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
    };

    return logos[domain];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: _domain.isNotEmpty && _getLogoUrl(_domain) != null
                ? _getLogoUrl(_domain)!.endsWith('.svg')
                    ? SvgPicture.network(
                        _getLogoUrl(_domain)!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Image.network(
                        _getLogoUrl(_domain)!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.link, color: Colors.grey);
                        },
                      )
                : const Icon(Icons.link, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(widget.isEditing ? 'Edit Item' : 'Add Item')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'URL Link'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.paste, color: Colors.grey),
                  tooltip: 'Paste',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _urlController.text = data.text!;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final priceText = _priceController.text.trim();
            final urlText = _urlController.text.trim();
            
            if (name.isEmpty || priceText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a name and price')),
              );
              return;
            }
            
            final price = double.tryParse(priceText) ?? 0.0;
            
            final newItem = MyListItem(
              id: widget.existingItem?.id ?? const Uuid().v4(),
              name: name,
              price: price,
              url: urlText,
              domain: _domain.isNotEmpty ? _domain : null,
              isPurchased: widget.existingItem?.isPurchased ?? false,
            );

            widget.onAdd(newItem);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
