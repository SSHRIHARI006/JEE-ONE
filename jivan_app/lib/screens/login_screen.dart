import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController(
    text: 'admin@jeevan.ai',
  );
  final TextEditingController passwordController = TextEditingController(
    text: '123456',
  );

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandBar(),
          const SizedBox(height: 20),

          const AppPageHeader(
            eyebrow: 'Welcome',
            title: 'Login to Jeevan',
            subtitle:
                'Access emergency reporting, triage, routing and handover.',
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _AuthField(
                  controller: emailController,
                  hint: 'Email',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  controller: passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: 'Login',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'Need a new account?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.go('/signup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => context.go('/'),
              child: const Text(
                'Continue in demo mode',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '✱',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Jeevan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'SECURE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
