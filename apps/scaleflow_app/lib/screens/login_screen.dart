import 'package:flutter/material.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';
import 'home_screen.dart';

// ---------------------------------------------------------------------------
// Example credentials (shown as hints in the UI)
// ---------------------------------------------------------------------------
const _exampleUsers = [
  _ExampleUser(username: 'operator', password: 'operator123', role: 'Location'),
  _ExampleUser(username: 'admin', password: 'admin123', role: 'Admin'),
];

class _ExampleUser {
  const _ExampleUser({required this.username, required this.password, required this.role});
  final String username;
  final String password;
  final String role;
}

// ---------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole; // 'Location' or 'Admin'
  Location? _selectedLocation;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_selectedRole == 'Location') {
      if (username == 'operator' && password == 'operator123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(location: _selectedLocation, isAdmin: false),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Invalid username or password.');
      }
    } else {
      if (username == 'admin' && password == 'admin123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(location: null, isAdmin: true),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Invalid username or password.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.scale, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ScaleFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
                ),
                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2B3C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username
                        _FieldLabel(label: 'Username'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _usernameController,
                          hint: 'Enter username',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Password
                        _FieldLabel(label: 'Password'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _passwordController,
                          hint: 'Enter password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Role dropdown
                        _FieldLabel(label: 'Role'),
                        const SizedBox(height: 8),
                        _DropdownField<String>(
                          value: _selectedRole,
                          hint: 'Select role',
                          prefixIcon: Icons.badge_outlined,
                          items: const ['Location', 'Admin'],
                          itemLabel: (r) => r,
                          onChanged: (v) => setState(() {
                            _selectedRole = v;
                            _selectedLocation = null;
                          }),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Location dropdown — visible only when role == Location
                        if (_selectedRole == 'Location') ...[
                          _FieldLabel(label: 'Location'),
                          const SizedBox(height: 8),
                          _DropdownField<Location>(
                            value: _selectedLocation,
                            hint: 'Select location',
                            prefixIcon: Icons.location_on_outlined,
                            items: mockLocations,
                            itemLabel: (l) => '${l.name}  •  ${l.city}, ${l.state}',
                            onChanged: (v) => setState(() => _selectedLocation = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF5350), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Sign in button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Example credentials hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXAMPLE LOGINS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._exampleUsers.map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              _HintChip(label: u.role),
                              const SizedBox(width: 10),
                              Text(
                                '${u.username} / ${u.password}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: _inputDecoration(hint, prefixIcon, suffixIcon),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  final T? value;
  final String hint;
  final IconData prefixIcon;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E3246),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
      decoration: _inputDecoration(hint, prefixIcon, null),
      hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15)),
      validator: validator,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData prefixIcon, Widget? suffixIcon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
    prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFF0D1B2A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF5350)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
    errorStyle: const TextStyle(color: Color(0xFFEF5350)),
  );
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isAdmin = label == 'Admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isAdmin ? const Color(0xFF6A1B9A) : const Color(0xFF1565C0)).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAdmin ? const Color(0xFFCE93D8) : const Color(0xFF90CAF9),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
