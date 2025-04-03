import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/providers/theme_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileImageSection extends StatelessWidget {
  final VoidCallback onPickImage;
  final ImageProvider? profileImage;
  final Widget? profileImageWidget;
  final String? email;

  const ProfileImageSection({
    super.key,
    required this.onPickImage,
    required this.profileImage,
    this.profileImageWidget,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: profileImage,
                child: profileImageWidget,
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
        Text(
          email ?? 'No email',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

class CurrencyInfoDialog extends StatelessWidget {
  final Map<String, dynamic> currencyInfo;

  const CurrencyInfoDialog({
    super.key,
    required this.currencyInfo,
  });

  @override
  Widget build(BuildContext context) {
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
            leading:
                Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
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
  }
}

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class PasswordChangeDialog extends StatefulWidget {
  final BuildContext parentContext;

  const PasswordChangeDialog({
    super.key,
    required this.parentContext,
  });

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;
  String? _changePasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
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
            PasswordField(
              controller: _currentPasswordController,
              labelText: 'Current Password',
              prefixIcon: Icons.lock,
              obscureText: _obscureCurrentPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
              enabled: !_isChangingPassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _newPasswordController,
              labelText: 'New Password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureNewPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              helperText: 'At least 6 characters',
              enabled: !_isChangingPassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPasswordController,
              labelText: 'Confirm New Password',
              prefixIcon: Icons.lock_reset,
              obscureText: _obscureConfirmPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              enabled: !_isChangingPassword,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isChangingPassword ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isChangingPassword ? null : _changePassword,
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
  }

  void _changePassword() async {
    // Clear any previous errors
    setState(() {
      _changePasswordError = null;
    });

    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        _changePasswordError = 'Please enter your current password';
      });
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _changePasswordError = 'Please enter a new password';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _changePasswordError = 'Password must be at least 6 characters';
      });
      return;
    }

    if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() {
        _changePasswordError = 'Passwords do not match';
      });
      return;
    }

    // Start loading
    setState(() {
      _isChangingPassword = true;
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
        password: _currentPasswordController.text,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      // Close dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
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

      setState(() {
        _changePasswordError = errorMessage;
        _isChangingPassword = false;
      });
    }
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final String? helperText;
  final bool enabled;

  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.obscureText,
    required this.onToggleObscure,
    this.helperText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggleObscure,
        ),
        helperText: helperText,
      ),
      obscureText: obscureText,
      enabled: enabled,
    );
  }
}

class ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String? selectedCurrency;
  final List<String> currencies;
  final Map<String, String> currencySymbols;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onInfoPressed;
  final VoidCallback onSaveProfile;

  const ProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.selectedCurrency,
    required this.currencies,
    required this.currencySymbols,
    required this.onCurrencyChanged,
    required this.onInfoPressed,
    required this.onSaveProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
              suffixIcon: nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        nameController.clear();
                      },
                    )
                  : null,
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
            value: selectedCurrency,
            decoration: InputDecoration(
              labelText: 'Preferred Currency',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_exchange),
              suffixIcon: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: onInfoPressed,
                tooltip: 'Currency Info',
              ),
            ),
            items: currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text('$currency (${currencySymbols[currency]})'),
              );
            }).toList(),
            onChanged: onCurrencyChanged,
          ),

          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: onSaveProfile,
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
    );
  }
}
