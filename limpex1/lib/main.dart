import 'package:flutter/material.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/login_view.dart';
import 'views/home_view.dart'; // Import da nova HomeView

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LimpeX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthViewModel _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  void _verificarSessao() async {
    final isLogged = await _authViewModel.checkAutoLogin();

    if (!mounted) return;

    if (isLogged && _authViewModel.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeView(user: _authViewModel.currentUser!),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}