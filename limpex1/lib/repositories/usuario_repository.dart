import '../models/usuario.dart';

class UsuarioRepository {
  final List<Usuario> _usuarios = [];

  void cadastrar(Usuario usuario) {
    _usuarios.add(usuario);
  }

  List<Usuario> listar() {
    return List.unmodifiable(_usuarios);
  }
}