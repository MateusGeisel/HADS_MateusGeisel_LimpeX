import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/upload_service.dart';

class ImageUploaderWidget extends StatefulWidget {
  final ValueChanged<String> onImageUploaded;

  const ImageUploaderWidget({super.key, required this.onImageUploaded});

  @override
  State<ImageUploaderWidget> createState() => _ImageUploaderWidgetState();
}

class _ImageUploaderWidgetState extends State<ImageUploaderWidget> {
  String? _imageUrl;
  bool _isUploading = false;

  Future<void> _upload() async {
    setState(() => _isUploading = true);
    try {
      final file = await UploadService.pickImage(ImageSource.gallery);
      if (file == null || !mounted) return;

      final url = await UploadService.uploadImage(file);
      if (!mounted) return;

      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar a imagem.')),
        );
        return;
      }

      setState(() => _imageUrl = url);
      widget.onImageUploaded(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
      );
      debugPrint('Erro ao selecionar ou enviar imagem: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _imageUrl!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 120,
                width: 120,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _isUploading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: _upload,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_imageUrl == null ? 'Adicionar Foto' : 'Alterar Foto'),
              ),
      ],
    );
  }
}