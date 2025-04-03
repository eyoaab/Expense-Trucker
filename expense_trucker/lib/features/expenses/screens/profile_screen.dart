import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/network_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/profile_widgets.dart';

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

                  // Profile Image Section
                  ProfileImageSection(
                    onPickImage: _pickImage,
                    profileImage: _getProfileImage(user, userData),
                    profileImageWidget: _getProfileImageWidget(user, userData),
                    email: user?.email,
                  ),

                  const SizedBox(height: 24),

                  // Profile Form
                  ProfileForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    selectedCurrency: _selectedCurrency,
                    currencies: CurrencyUtils.availableCurrencies,
                    currencySymbols: CurrencyUtils.currencySymbols,
                    onCurrencyChanged: (value) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    },
                    onInfoPressed: _showCurrencyInfoDialog,
                    onSaveProfile: _saveProfile,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Settings Section
                  SettingsListTile(
                    icon: Icons.dark_mode,
                    title: 'App Theme',
                    subtitle: _getThemeText(
                        Provider.of<ThemeProvider>(context).themeMode),
                    onTap: _showThemeSelectionDialog,
                  ),

                  SettingsListTile(
                    icon: Icons.security,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: _showChangePasswordDialog,
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

  ImageProvider? _getProfileImage(
      firebaseAuth.User? user, UserModel? userData) {
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

  Widget? _getProfileImageWidget(firebaseAuth.User? user, UserModel? userData) {
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

  void _showCurrencyInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currencyInfo =
            CurrencyUtils.getCurrencyInfo(_selectedCurrency ?? 'ETB');
        return CurrencyInfoDialog(currencyInfo: currencyInfo);
      },
    );
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.system:
        return 'System Default';
      default:
        return 'System Default';
    }
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ThemeSelectionDialog();
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return PasswordChangeDialog(parentContext: context);
      },
    );
  }

  void _changePasswordInternal(
    Function(Function()) setDialogState,
    BuildContext dialogContext,
    String currentPassword,
    String newPassword,
    String confirmPassword,
    Function(String) setError,
    Function startLoading,
    Function endLoading,
  ) async {
    // Clear any previous errors
    setError('');

    // Validate inputs
    if (currentPassword.isEmpty) {
      setError('Please enter your current password');
      return;
    }

    if (newPassword.isEmpty) {
      setError('Please enter a new password');
      return;
    }

    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    if (confirmPassword != newPassword) {
      setError('Passwords do not match');
      return;
    }

    // Start loading
    startLoading();

    try {
      // Get current user
      final user = firebaseAuth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's email
      final email = user.email;

      if (email == null || email.isEmpty) {
        throw Exception('User email not found');
      }

      // Create a credential with the current password
      final credential = firebaseAuth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Close dialog
      Navigator.pop(dialogContext);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = 'Failed to update password';

      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage =
            'For security reasons, please log in again before changing your password';
      }

      setError(errorMessage);
      endLoading();
    }
  }

  Future<void> _changePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = firebaseAuth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's email
      final email = user.email;

      if (email == null || email.isEmpty) {
        throw Exception('User email not found');
      }

      // Create a credential with the current password
      final credential = firebaseAuth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = 'Failed to update password';

      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage =
            'For security reasons, please log in again before changing your password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
