import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Моля, въведи име.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_name',
      name,
    );

    await prefs.setBool(
      'is_logged_in',
      true,
    );

    if (!mounted) {
      return;
    }

    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --------------------------------------------------
                  // STREAKLY LOGO
                  // --------------------------------------------------

                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icon/streakly_icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // APP NAME
                  // --------------------------------------------------

                  const Text(
                    'Habit Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --------------------------------------------------
                  // DESCRIPTION
                  // --------------------------------------------------

                  Text(
                    'Изгради добри навици.\n'
                    'Един ден наведнъж.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 42),

                  // --------------------------------------------------
                  // NAME LABEL
                  // --------------------------------------------------

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Как да те наричаме?',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --------------------------------------------------
                  // NAME INPUT
                  // --------------------------------------------------

                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Въведи името си',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(16),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _continue(),
                  ),

                  const SizedBox(height: 18),

                  // --------------------------------------------------
                  // CONTINUE BUTTON
                  // --------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            AppColors.accent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Продължи',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
