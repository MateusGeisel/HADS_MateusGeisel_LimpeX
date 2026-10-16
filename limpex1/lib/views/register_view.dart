import 'package:flutter/material.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  String _tipoPerfilSelecionado = 'CLIENTE';
  final _authViewModel = AuthViewModel();

  void _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _authViewModel.register(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
      tipoPerfil: _tipoPerfilSelecionado,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso! Faça seu login.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authViewModel.errorMessage ?? 'Erro no cadastro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LimpeX - Criar Conta')),
      body: AnimatedBuilder(
        animation: _authViewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tipo de Perfil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'CLIENTE', label: Text('Quero Contratar')),
                      ButtonSegment(value: 'PRESTADOR', label: Text('Quero Trabalhar')),
                    ],
                    selected: {_tipoPerfilSelecionado},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _tipoPerfilSelecionado = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome Completo *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-mail *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(labelText: 'Senha *', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(labelText: 'Telefone (opcional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cpfController,
                    decoration: const InputDecoration(labelText: 'CPF (opcional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _authViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: _cadastrar,
                          child: const Text('Cadastrar Conta', style: TextStyle(fontSize: 16)),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}