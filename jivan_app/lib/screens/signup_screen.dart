import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_shell_scaffold.dart';
import '../widgets/primary_action_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController(
    text: 'Ankit',
  );
  final TextEditingController emailController = TextEditingController(
    text: 'ankit@jeevan.ai',
  );
  final TextEditingController roleController = TextEditingController(
    text: 'Ambulance Staff',
  );
  final TextEditingController passwordController = TextEditingController(
    text: '123456',
  );

  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    roleController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBar(onBack: () => context.go('/login')),
          const SizedBox(height: 20),

          const AppPageHeader(
            eyebrow: 'Signup',
            title: 'Create your account',
            subtitle:
                'Register to access emergency workflows and hospital coordination.',
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
                  controller: nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  controller: emailController,
                  hint: 'Email',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  controller: roleController,
                  hint: 'Role',
                  icon: Icons.badge_outlined,
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
                  label: 'Create Account',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Already have an account? Login',
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
  final VoidCallback onBack;

  const _BrandBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Jeevan',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
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
