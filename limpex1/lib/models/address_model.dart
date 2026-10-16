class AddressModel {
  final int? idEndereco;
  final int? idUsuario;
  final String cep;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final double? latitude;
  final double? longitude;

  AddressModel({
    this.idEndereco,
    this.idUsuario,
    required this.cep,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      idEndereco: json['id_endereco'],
      idUsuario: json['id_usuario'],
      cep: json['cep'],
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}