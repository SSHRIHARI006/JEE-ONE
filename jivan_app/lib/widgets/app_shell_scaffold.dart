import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppShellScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppShellScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double horizontalPadding = width < 380 ? 14 : 18;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: child,
        ),
      ),
    );
  }
}
