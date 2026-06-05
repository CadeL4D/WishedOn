import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/wishlists_screen.dart';
import 'screens/join_group_screen.dart';
import 'services/database_service.dart';

void main() async {
  // Ensure that plugin services are initialized before Firebase setup
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the environment-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WishedOn',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.trackpad},
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D5FEF)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        // Handle /join/<CODE> deep link
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments[0] == 'join' &&
            uri.pathSegments[1].isNotEmpty) {
          final joinCode = uri.pathSegments[1].toUpperCase();
          return MaterialPageRoute(
            builder: (context) => _JoinCodeResolver(joinCode: joinCode),
          );
        }

        // Default route — use AuthWrapper for all other paths
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        );
      },
    );
  }
}

/// Resolves a join code from a deep link URL, looks up the group in Firestore,
/// and navigates to the JoinGroupScreen if found.
class _JoinCodeResolver extends StatefulWidget {
  final String joinCode;
  const _JoinCodeResolver({required this.joinCode});

  @override
  State<_JoinCodeResolver> createState() => _JoinCodeResolverState();
}

class _JoinCodeResolverState extends State<_JoinCodeResolver> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveCode();
  }

  Future<void> _resolveCode() async {
    try {
      final groupDoc = await _databaseService.getGroupByCode(widget.joinCode);
      if (!mounted) return;

      if (groupDoc != null) {
        final data = groupDoc.data() as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JoinGroupScreen(
              initialGroupId: groupDoc.id,
              initialGroupName: data['name'] ?? 'Unknown Group',
              initialGroupCode: widget.joinCode,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid group code. This link may have expired.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5D5FEF)),
                  SizedBox(height: 24),
                  Text(
                    'Finding your group...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'An error occurred.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final activeGroupId = prefs.getString('activeGroupId');
    final isOwner = prefs.getBool('isOwner') ?? false;

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (activeGroupId != null && activeGroupId.isNotEmpty) {
      // User was active in a specific group session
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WishlistsScreen(isOwner: isOwner),
        ),
      );
    } else if (user != null) {
      // User is logged into an account but not an active group
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } else {
      // Clean slate default to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF5D5FEF)),
      ),
    );
  }
}
