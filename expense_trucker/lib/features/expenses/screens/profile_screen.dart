import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/network_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _profileImage;
  Uint8List? _webProfileImage;
  XFile? _pickedFile;
  bool _isLoading = false;
  String? _selectedCurrency;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'BRL'
  ];

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'BRL': 'R\$',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null) {
      _nameController.text = userData.name;
      setState(() {
        _selectedCurrency = userData.preferredCurrency;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        if (kIsWeb) {
          pickedFile.readAsBytes().then((value) {
            setState(() {
              _webProfileImage = value;
            });
          });
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;

        if (user == null) {
          throw Exception('User not logged in');
        }

        String? photoUrl;

        // Upload profile image if one was selected
        if (kIsWeb && _webProfileImage != null) {
          photoUrl = await NetworkUtils.uploadProfileImageWeb(
              user.uid,
              _webProfileImage!,
              _pickedFile?.name ??
                  'profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
        } else if (!kIsWeb && _profileImage != null) {
          photoUrl =
              await NetworkUtils.uploadProfileImage(user.uid, _profileImage!);
        }

        // Update user profile in Firestore
        await authProvider.updateUserProfile(
          name: _nameController.text,
          preferredCurrency: _selectedCurrency!,
          photoUrl: photoUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();

        if (mounted) {
          // Navigate to login screen and clear navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userData = authProvider.userData;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          backgroundImage: _getProfileImage(user, userData),
                          child: _getProfileImageWidget(user, userData),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email display
                  Text(
                    user?.email ?? 'No email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 24),

                  // Profile Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Currency dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Currency',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_exchange),
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(
                                  '$currency (${_currencySymbols[currency]})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Save button
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Additional settings
                  ListTile(
                    leading: Icon(
                      Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('App Theme'),
                    subtitle: const Text('Change app appearance'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show theme selection dialog
                      // This will be implemented in a separate PR
                    },
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Reset Password'),
                    subtitle: const Text('Change your account password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to reset password screen or show dialog
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sign out button
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      foregroundColor: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  ImageProvider? _getProfileImage(User? user, UserModel? userData) {
    if (kIsWeb && _webProfileImage != null) {
      return MemoryImage(_webProfileImage!);
    }

    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }

    if (userData != null &&
        userData.photoUrl != null &&
        userData.photoUrl!.isNotEmpty) {
      return NetworkImage(userData.photoUrl!);
    }

    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      return NetworkImage(user.photoURL!);
    }

    return null;
  }

  Widget? _getProfileImageWidget(User? user, UserModel? userData) {
    // Show initials if no image is available
    if ((kIsWeb && _webProfileImage == null && _profileImage == null) ||
        (!kIsWeb && _profileImage == null)) {
      if ((userData == null ||
              userData.photoUrl == null ||
              userData.photoUrl!.isEmpty) &&
          (user?.photoURL == null || user!.photoURL!.isEmpty)) {
        String initials = '';
        if (_nameController.text.isNotEmpty) {
          initials = _nameController.text
              .trim()
              .split(' ')
              .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
              .join();
        } else if (userData != null && userData.name.isNotEmpty) {
          initials = userData.name
              .trim()
              .split(' ')
              .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
              .join();
        } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
          initials = user.displayName!
              .trim()
              .split(' ')
              .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
              .join();
        } else if (user?.email != null) {
          initials = user!.email![0].toUpperCase();
        }

        if (initials.isNotEmpty) {
          return Text(
            initials.length > 2 ? initials.substring(0, 2) : initials,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        );
      }
    }

    return null;
  }
}
