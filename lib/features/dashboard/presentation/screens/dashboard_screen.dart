import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: contenu différent selon le rôle (membre vs formateur),
    // à brancher sur un provider `currentUserRoleProvider`.
    return const Scaffold(
      body: Center(child: Text('Dashboard — à implémenter')),
    );
  }
}
