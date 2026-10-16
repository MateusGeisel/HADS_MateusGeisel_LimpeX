import 'tipo_perfil.dart';

class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String senha;
  final TipoPerfil tipoPerfil;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipoPerfil,
  });
}