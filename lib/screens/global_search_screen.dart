import 'package:flutter/material.dart';
import '../widgets/search_bar_widget.dart';

class GlobalSearchScreen extends StatelessWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: GlobalSearchBar(),
      ),
    );
  }
}
