import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../services/database_service.dart';
import 'wishlists_screen.dart';

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8); // Max 8 digits

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int nonZeroIndex = i + 1;
      // Add a slash after 2nd and 4th digits
      if ((nonZeroIndex == 2 || nonZeroIndex == 4) && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class JoinGroupScreen extends StatefulWidget {
  final String initialGroupId;
  final String initialGroupName;
  final String initialGroupCode;
  final String? initialGroupOwnerUid;

  const JoinGroupScreen({
    super.key, 
    required this.initialGroupId, 
    required this.initialGroupName, 
    required this.initialGroupCode,
    this.initialGroupOwnerUid,
  });

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController(text: '🐶');
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = false;
  
  // Group data passed in
  late final String _foundGroupId;
  late final String _foundGroupName;
  late final String? _foundGroupOwnerUid;
  
  // User auth details
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _foundGroupId = widget.initialGroupId;
    _foundGroupName = widget.initialGroupName;
    _foundGroupOwnerUid = widget.initialGroupOwnerUid;
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _emojiController.text = emoji.emoji;
              Navigator.pop(context);
            },
          ),
        );
      }
    );
  }

  // Old claim member process, updated to ask for PIN first
  Future<void> _loginAsGuest(String memberId, String storedPin) async {
    // Instead of forcing a claim, we just authenticate them locally as this guest
    if (_currentUserId != null) {
      // If the user *is* logged in to a Firebase account, we'll link it for convenience
      try {
        await _databaseService.claimExistingMember(_foundGroupId, memberId, _currentUserId!);
      } catch (e) {
        // Just log the error, don't stop them from entering the group session
        print('Error silently linking profile: $e');
      }
    }

    _completeJoinFlow(_foundGroupId, memberId);
  }

  Future<void> _showPinDialog(String memberId, String name, String storedPin) async {
    final TextEditingController pinInputController = TextEditingController();
    String errorText = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Enter PIN for $name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter the 4-digit PIN for this profile.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinInputController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'PIN',
                      errorText: errorText.isNotEmpty ? errorText : null,
                      filled: true,
                      fillColor: const Color(0xFFF6F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (errorText.isNotEmpty) {
                        setDialogState(() => errorText = '');
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pinInputController.text == storedPin || storedPin.isEmpty) {
                      Navigator.pop(context);
                      _loginAsGuest(memberId, storedPin);
                    } else {
                      setDialogState(() {
                        errorText = 'Incorrect PIN';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5FEF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Enter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _showCreatePinDialog(String memberId, String name) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    String errorText = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Create PIN for $name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your PIN was reset by the group owner. Please create a new 4-digit PIN.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'New PIN',
                      filled: true,
                      fillColor: const Color(0xFFF6F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (errorText.isNotEmpty) setDialogState(() => errorText = '');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirm PIN',
                      errorText: errorText.isNotEmpty ? errorText : null,
                      filled: true,
                      fillColor: const Color(0xFFF6F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (errorText.isNotEmpty) setDialogState(() => errorText = '');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin1 = pinController.text;
                    final pin2 = confirmPinController.text;
                    
                    if (pin1.length != 4 || int.tryParse(pin1) == null) {
                      setDialogState(() => errorText = 'PIN must be 4 digits');
                      return;
                    }
                    if (pin1 != pin2) {
                      setDialogState(() => errorText = 'PINs do not match');
                      return;
                    }
                    
                    Navigator.pop(context);
                    
                    setState(() => _isLoading = true);
                    try {
                      await _databaseService.resetMemberPin(_foundGroupId, memberId, pin1);
                      await _loginAsGuest(memberId, pin1);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving PIN: $e')),
                        );
                      }
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5FEF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save & Enter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _joinAsViewer() async {
    // Save active session data locally, but without a memberId
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeGroupId', _foundGroupId);
    await prefs.remove('activeMemberId'); // Ensure no member is set
    await prefs.setBool('isOwner', false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WishlistsScreen(isOwner: false),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _joinAsNewGuest() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final birthdate = _birthdateController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your new profile.')),
      );
      return;
    }
    
    if (birthdate.isEmpty || birthdate.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid birthdate (MM/DD/YYYY).')),
      );
      return;
    }
    
    if (pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // The DatabaseService currently expects both code and name to create the guest profile.
      final result = await _databaseService.joinGroupAsGuest(
        widget.initialGroupCode, 
        name,
        birthdate: birthdate,
        pin: pin,
        emoji: _emojiController.text.trim(),
      );
      if (result != null) {
        // If the current user is logged in, we also want to add their UID to the group's memberIds array so it shows on dashboard.
        if (_currentUserId != null) {
          await _databaseService.claimExistingMember(result['groupId']!, result['memberId']!, _currentUserId!);
        }
        _completeJoinFlow(result['groupId']!, result['memberId']!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating guest profile: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeJoinFlow(String groupId, String memberId) async {
    // Save active session data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeGroupId', groupId);
    await prefs.setString('activeMemberId', memberId);
    await prefs.setBool('isOwner', false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WishlistsScreen(isOwner: false),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _pinController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text('Join ${_foundGroupName}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SafeArea(
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _databaseService.getGroupMembersStream(_foundGroupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allMembers = snapshot.data?.docs ?? [];
              // Filter out: registered owner, owner by UID, and profiles already claimed by someone else
              final members = allMembers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isRegisteredOwner'] == true) return false;
                if (doc.id == _foundGroupOwnerUid) return false;
                final claimed = data['claimedByUid'] as String?;
                // Allow if unclaimed OR if claimed by the current user (so they can re-enter)
                if (claimed != null && claimed.isNotEmpty && claimed != _currentUserId) return false;
                return true;
              }).toList();
              
              if (members.isEmpty) {
                return const Center(child: Text('No members found yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: members.length + 1, // Add 1 for the title
                itemBuilder: (context, index) {
                  if (index == 0) {
                     return const Padding(
                       padding: EdgeInsets.only(bottom: 16.0),
                       child: Text(
                         'Claim an existing profile:',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                     );
                  }

                  final doc = members[index - 1];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown Member';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF5D5FEF).withAlpha((0.1 * 255).toInt()),
                        child: Text(
                          (data['emoji'] != null && data['emoji'].toString().isNotEmpty) 
                            ? data['emoji'] 
                            : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                          style: TextStyle(
                            color: const Color(0xFF5D5FEF), 
                            fontWeight: FontWeight.bold,
                            fontSize: (data['emoji'] != null && data['emoji'].toString().isNotEmpty) ? 20 : 14,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _isLoading ? null : () {
                        final storedPin = data['pin'] as String?;
                        if (storedPin == null || storedPin.isEmpty) {
                          _showCreatePinDialog(doc.id, name);
                        } else {
                          _showPinDialog(doc.id, name, storedPin);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Create New Member Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Or create a new member profile:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _emojiController,
                      readOnly: true,
                      canRequestFocus: false,
                      onTap: _showEmojiPicker,
                      decoration: InputDecoration(
                        labelText: 'Icon',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                      maxLength: 1,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthdateController,
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  hintText: 'MM/DD/YYYY',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.grey),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final month = picked.month.toString().padLeft(2, '0');
                        final day = picked.day.toString().padLeft(2, '0');
                        final year = picked.year.toString();
                        _birthdateController.text = '$month/$day/$year';
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [DateTextFormatter()],
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Create 4-Digit PIN',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _joinAsNewGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C48C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Join as New Member',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _joinAsViewer,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: const BorderSide(color: Color(0xFF5D5FEF), width: 1.5),
                  ),
                  child: const Text(
                    'View Wishlists Only',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5D5FEF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

