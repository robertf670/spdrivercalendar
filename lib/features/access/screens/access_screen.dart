import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/config/web_access_config.dart';

/// Web-only access gate. User must enter Work Access Code to use the PWA.
/// Once granted, access is persisted and never asked again.
class AccessScreen extends StatefulWidget {
  final VoidCallback onAccessGranted;

  const AccessScreen({
    super.key,
    required this.onAccessGranted,
  });

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateAccessCode(String input) {
    final inputHash = sha256.convert(utf8.encode(input)).toString();
    return inputHash == workAccessCodeHash;
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the access code';
        _isLoading = false;
      });
      return;
    }

    if (_validateAccessCode(code)) {
      await StorageService.saveBool(AppConstants.workAccessGrantedKey, true);
      if (!mounted) return;
      widget.onAccessGranted();
    } else {
      setState(() {
        _errorMessage = 'Incorrect access code';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Work Access',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the access code to use this app',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _controller,
                      obscureText: _obscureText,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Access Code',
                        hintText: 'Enter code',
                        border: const OutlineInputBorder(),
                        errorText: _errorMessage,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
