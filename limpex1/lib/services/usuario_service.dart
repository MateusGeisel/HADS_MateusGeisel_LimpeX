import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

class UsuarioService {
  final UsuarioRepository repository;

  UsuarioService(this.repository);

  void cadastrar(Usuario usuario) {
    if (usuario.nome.trim().isEmpty) {
      throw Exception('O nome é obrigatório.');
    }

    if (usuario.email.trim().isEmpty) {
      throw Exception('O e-mail é obrigatório.');
    }

    if (!usuario.email.contains('@')) {
      throw Exception('O e-mail é inválido.');
    }

    if (usuario.senha.length < 6) {
      throw Exception('A senha deve ter pelo menos 6 caracteres.');
    }

    repository.cadastrar(usuario);
  }

  List<Usuario> listar() {
    return repository.listar();
  }
}