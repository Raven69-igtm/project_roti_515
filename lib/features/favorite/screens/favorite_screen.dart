import 'package:flutter/material.dart';

import '../widgets/favorite_app_bar.dart';
import '../widgets/favorite_grid.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: Stack(
        children: [
          FavoriteGrid(),
          FavoriteAppBar(),
        ],
      ),
    );
  }
}
