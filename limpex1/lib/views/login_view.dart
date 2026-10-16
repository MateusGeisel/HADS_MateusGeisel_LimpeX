import 'package:flutter/material.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'home_view.dart'; // Import da HomeView

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authViewModel = AuthViewModel();

  void _fazerLogin() async {
    final success = await _authViewModel.login(
      _emailController.text,
      _senhaController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bem-vindo, ${_authViewModel.currentUser?.nome}!')),
      );

      // Redireciona para a HomeView passando o utilizador logado
      if (_authViewModel.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeView(user: _authViewModel.currentUser!),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authViewModel.errorMessage ?? 'Erro no login'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LimpeX - Login')),
      body: AnimatedBuilder(
        animation: _authViewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _authViewModel.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _fazerLogin,
                        child: const Text('Entrar'),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterView()),
                    );
                  },
                  child: const Text('Não tem uma conta? Cadastre-se'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}