import 'package:flutter/material.dart';

class AppBarFinances extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileAction;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppBarFinances({ 
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showProfileAction = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> appBarActions = [];

    if (showProfileAction) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.account_circle),
          color: Colors.white,
          iconSize: 28,
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      );
    }

    if (actions != null && actions!.isNotEmpty) {
      appBarActions.addAll(actions!);
    }

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0B0D39),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      elevation: 4,
      shadowColor: Colors.black,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}