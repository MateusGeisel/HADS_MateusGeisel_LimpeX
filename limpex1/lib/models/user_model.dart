class UserModel {
  final int id;
  final String nome;
  final String email;
  final String? cpf;
  final String? telefone;
  final String tipoPerfil; // 'CLIENTE', 'PRESTADOR' ou 'AMBOS'

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.cpf,
    this.telefone,
    this.tipoPerfil = 'CLIENTE',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['id_usuario'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpf: json['cpf'],
      telefone: json['telefone'],
      tipoPerfil: json['tipo_perfil'] ?? 'CLIENTE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'tipo_perfil': tipoPerfil,
    };
  }
}