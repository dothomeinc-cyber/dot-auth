import 'package:flutter/material.dart';

/// Stand-in for your Terms and Privacy pages.
///
/// `TcFooter` opens these with `push`, so the back button returns the user to
/// the auth screen they came from.
class LegalPage extends StatelessWidget {
  final String title;

  const LegalPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Your legal copy goes here.'),
      ),
    );
  }
}
