import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_shell.dart';

void main() {
  runApp(const LoanAppBootstrap());
}

class LoanAppBootstrap extends StatefulWidget {
  const LoanAppBootstrap({super.key});

  @override
  State<LoanAppBootstrap> createState() => _LoanAppBootstrapState();
}

class _LoanAppBootstrapState extends State<LoanAppBootstrap> {
  late final Future<AppController> _controllerFuture;
  AppController? _controller;

  @override
  void initState() {
    super.initState();
    _controllerFuture = AppController.create();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nicha Loan Desk',
      theme: _buildTheme(),
      home: FutureBuilder<AppController>(
        future: _controllerFuture,
        builder: (BuildContext context, AsyncSnapshot<AppController> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingScreen();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorScreen(
              message:
                  snapshot.error?.toString() ?? 'Unable to load app state.',
            );
          }
          _controller ??= snapshot.data!;
          return LoanAppShell(controller: _controller!);
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5E34),
      brightness: Brightness.light,
      surface: const Color(0xFFFBF7F2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F1EA),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
