import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: vérifier la session Supabase existante puis rediriger
    // vers /login ou /dashboard.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
