import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/utils/network_utils.dart';
import '../../../core/providers/theme_provider.dart';
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
    'ETB',
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
    'ETB': 'Br',
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
          ? Center(
              child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
            ))
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
                              .secondary
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
                          decoration: InputDecoration(
                            labelText: 'Preferred Currency',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.currency_exchange),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                _showCurrencyInfoDialog();
                              },
                              tooltip: 'Currency Info',
                            ),
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
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    title: const Text('App Theme'),
                    subtitle: Text(_getThemeText(
                        Provider.of<ThemeProvider>(context).themeMode)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showThemeSelectionDialog,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              color: Theme.of(context).colorScheme.secondary,
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

  Map<String, dynamic> _getCurrencyInfo(String currencyCode) {
    final Map<String, Map<String, dynamic>> currencyInfo = {
      'ETB': {
        'name': 'Ethiopian Birr',
        'code': 'ETB',
        'symbol': 'Br',
        'country': 'Ethiopia',
        'info':
            'The Birr has been the currency of Ethiopia since 1893. The name "Birr" comes from the local word for silver. It is subdivided into 100 santim.'
      },
      'USD': {
        'name': 'US Dollar',
        'code': 'USD',
        'symbol': '\$',
        'country': 'United States',
        'info': 'The world\'s primary reserve currency.'
      },
      'EUR': {
        'name': 'Euro',
        'code': 'EUR',
        'symbol': '€',
        'country': 'Euro Zone',
        'info':
            'Official currency of 19 of the 27 member states of the European Union.'
      },
      'GBP': {
        'name': 'British Pound',
        'code': 'GBP',
        'symbol': '£',
        'country': 'United Kingdom',
        'info': 'The world\'s oldest currency still in use.'
      },
      'JPY': {
        'name': 'Japanese Yen',
        'code': 'JPY',
        'symbol': '¥',
        'country': 'Japan',
        'info': 'Third most traded currency in the foreign exchange market.'
      },
      'CNY': {
        'name': 'Chinese Yuan',
        'code': 'CNY',
        'symbol': '¥',
        'country': 'China',
        'info': 'Official currency of the People\'s Republic of China.'
      },
      'INR': {
        'name': 'Indian Rupee',
        'code': 'INR',
        'symbol': '₹',
        'country': 'India',
        'info': 'The official currency of India.'
      }
    };

    // Default to USD if currency not found in our info map
    return currencyInfo[currencyCode] ??
        {
          'name': currencyCode,
          'code': currencyCode,
          'symbol': _currencySymbols[currencyCode] ?? currencyCode,
          'country': 'Multiple Countries',
          'info': 'No additional information available'
        };
  }

  void _showCurrencyInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currencyInfo = _getCurrencyInfo(_selectedCurrency ?? 'ETB');
        return AlertDialog(
          title: Text('${currencyInfo['name']} (${currencyInfo['code']})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.monetization_on,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Symbol'),
                subtitle: Text(currencyInfo['symbol']),
              ),
              ListTile(
                leading: Icon(Icons.flag,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Country'),
                subtitle: Text(currencyInfo['country']),
              ),
              if (currencyInfo['info'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(currencyInfo['info']!),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
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
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Select Theme'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light Theme'),
                subtitle: const Text('Use light colors'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: Theme.of(context).colorScheme.secondary,
                secondary: const Icon(Icons.light_mode),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Theme'),
                subtitle: const Text('Use dark colors'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: Theme.of(context).colorScheme.secondary,
                secondary: const Icon(Icons.nightlight_round),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: Theme.of(context).colorScheme.secondary,
                secondary: const Icon(Icons.auto_mode),
              ),
            ],
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

  void _showChangePasswordDialog() {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;
    bool _isChangingPassword = false;
    String? _changePasswordError;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Change Password'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_changePasswordError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _changePasswordError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrentPassword,
                      enabled: !_isChangingPassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        helperText: 'At least 6 characters',
                      ),
                      obscureText: _obscureNewPassword,
                      enabled: !_isChangingPassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isChangingPassword,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isChangingPassword ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () {
                          _changePasswordInternal(
                            setDialogState,
                            dialogContext,
                            _currentPasswordController.text,
                            _newPasswordController.text,
                            _confirmPasswordController.text,
                            (error) {
                              setDialogState(() {
                                _changePasswordError = error;
                              });
                            },
                            () {
                              setDialogState(() {
                                _isChangingPassword = true;
                              });
                            },
                            () {
                              setDialogState(() {
                                _isChangingPassword = false;
                              });
                            },
                          );
                        },
                  child: _isChangingPassword
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
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
