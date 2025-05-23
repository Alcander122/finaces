import 'package:flutter/material.dart';

class AppBarFinances extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;

  final VoidCallback? onProfilePressed;

  final bool showProfileIcon;

  final bool useLogoAsTitle;

  const AppBarFinances({
    super.key,
    this.title,
    this.actions,
    this.onProfilePressed,
    this.showProfileIcon = true,
    this.useLogoAsTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF003366),
      centerTitle: useLogoAsTitle ? true : false,
      title: useLogoAsTitle
          ? Center(
              child: Image.asset(
                'assets/images/logobill.png',
                height: 32,
                color: Colors.white,
              ),
            )
          : Text(
              title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
      actions: [
        if (actions != null) ...actions!,
        if (showProfileIcon)
          IconButton(
            icon: const Icon(Icons.account_circle),
            color: Colors.white,
            iconSize: 28,
            onPressed: onProfilePressed ??
                () {
                  Navigator.pushNamed(context, '/profile');
                },
          ),
      ],
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
