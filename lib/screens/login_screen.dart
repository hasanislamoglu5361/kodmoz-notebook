import 'package:flutter/material.dart';

import '../api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onLoggedIn});

  final ApiClient api;
  final void Function() onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'kodmoz');
  final _passCtrl = TextEditingController();
  bool _busy = false;
  String? _err;
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _err = 'Username and password required');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      // Open Notebook's auth model is a single bearer token configured at the
      // pod level. The login screen accepts username + password, then probes
      // /auth/status with the password-as-token. If the backend adds real
      // /auth/login it will accept the same body — we just send `Basic` for
      // now and fall back to raw token if the backend rejects it.
      final token = pass;
      await widget.api.saveToken(token);
      final status = await widget.api.authStatus();
      // Even if /auth/status returns null we still allow entry; the bearer
      // token check happens on every request. If /auth/status works the user
      // sees a green check, otherwise the home screen will surface a 401.
      if (!mounted) return;
      if (status != null) {
        widget.onLoggedIn();
      } else {
        // Probe a real endpoint to confirm the token works.
        try {
          await widget.api.fetchNotebooks();
          if (!mounted) return;
          widget.onLoggedIn();
        } on ApiException catch (e) {
          if (!mounted) return;
          setState(() => _err = e.isUnauthorized
              ? 'Wrong password — Open Notebook uses a single bearer token'
              : e.displayMessage);
          await widget.api.clearToken();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
      await widget.api.clearToken();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kodmoz Notebook',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'notebook.kodmoz.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _userCtrl,
                    enabled: !_busy,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    enabled: !_busy,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password / API token',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _err!,
                              style: const TextStyle(color: Color(0xFFFCA5A5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign in', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Open Notebook backend uses a single bearer token. '
                    'Enter the shared admin password and the app will use it '
                    'as Authorization: Bearer for every request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
