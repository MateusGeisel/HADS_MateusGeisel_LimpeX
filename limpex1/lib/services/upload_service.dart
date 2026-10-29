import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadService {
  static const String baseUrl = 'https://hads-mateusgeisel-limpex.onrender.com';

  // Selecionar imagem da galeria ou câmera
  static Future<XFile?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: source, imageQuality: 80);
  }

  // Enviar a imagem para a API
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Ler os bytes da imagem (funciona tanto no Android/iOS quanto na Web)
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'imagem',
        bytes,
        filename: imageFile.name,
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Retorna a URL pública gerada no Supabase
      } else {
        print('Erro no upload: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção no upload: $e');
      return null;
    }
  }
}