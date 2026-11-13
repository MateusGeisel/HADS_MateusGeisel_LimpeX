import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';
import '../services/address_service.dart';
import '../services/prestador_service.dart';
import '../services/upload_service.dart';
import 'prestador_formalizacao_view.dart';
import 'trilha_mei_view.dart';

class PrestadorProfileView extends StatefulWidget {
  const PrestadorProfileView({
    super.key,
    required this.user,
    this.prestadorService,
    this.addressService,
    this.onProfileUpdated,
  });

  final UserModel user;
  final PrestadorService? prestadorService;
  final AddressService? addressService;
  final ValueChanged<Map<String, dynamic>>? onProfileUpdated;

  @override
  State<PrestadorProfileView> createState() => _PrestadorProfileViewState();
}

class _PrestadorProfileViewState extends State<PrestadorProfileView> {
  late final PrestadorService _prestadorService;
  late final AddressService _addressService;
  final _profileFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  AddressModel? _address;
  Map<String, dynamic> _profile = {};
  String? _email;
  String? _profilePhoto;
  String? _profileError;
  String? _addressError;
  bool _loading = true;
  bool _savingProfile = false;
  bool _savingAddress = false;
  bool _searchingCep = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _prestadorService = widget.prestadorService ?? PrestadorService();
    _addressService = widget.addressService ?? AddressService();
    _nameController.text = widget.user.nome;
    _phoneController.text = widget.user.telefone ?? '';
    _email = widget.user.email;
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _profileError = null;
      _addressError = null;
    });

    try {
      final profile = await _prestadorService.buscarMeuPerfil();
      if (!mounted) return;
      _profile = profile;
      _nameController.text = profile['nome']?.toString() ?? '';
      _phoneController.text = profile['telefone']?.toString() ?? '';
      _bioController.text = profile['biografia']?.toString() ?? '';
      _email = profile['email']?.toString();
      _profilePhoto = profile['foto_perfil']?.toString();
    } catch (error) {
      _profileError = _errorMessage(
        error,
        'Não foi possível carregar os dados do perfil.',
      );
      if (!mounted) return;
    }

    try {
      final addresses = await _addressService.getAddresses();
      if (!mounted) return;
      _setAddress(addresses.isEmpty ? null : addresses.first);
    } catch (error) {
      if (!mounted) return;
      _addressError = _errorMessage(
        error,
        'Não foi possível carregar o endereço.',
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  void _setAddress(AddressModel? address) {
    _address = address;
    _cepController.text = address?.cep ?? '';
    _streetController.text = address?.rua ?? '';
    _numberController.text = address?.numero ?? '';
    _districtController.text = address?.bairro ?? '';
    _cityController.text = address?.cidade ?? '';
    _stateController.text = address?.estado ?? '';
  }

  String _errorMessage(Object error, String fallback) =>
      error is StateError ? error.message.toString() : fallback;

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectProfilePhoto() async {
    final image = await UploadService.pickImage(ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final url = await UploadService.uploadImage(image);
    if (!mounted) return;

    setState(() => _uploadingPhoto = false);
    if (url == null || url.isEmpty) {
      _showMessage(
        'Não foi possível enviar a foto. Tente novamente.',
        error: true,
      );
      return;
    }

    setState(() => _profilePhoto = url);
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    try {
      final profile = await _prestadorService.atualizarMeuPerfil(
        nome: _nameController.text.trim(),
        telefone: _phoneController.text.trim(),
        biografia: _bioController.text.trim(),
        fotoPerfil: _profilePhoto,
      );
      if (!mounted) return;
      setState(() {
        _profile = {..._profile, ...profile};
        _nameController.text = profile['nome']?.toString() ?? '';
        _phoneController.text = profile['telefone']?.toString() ?? '';
        _bioController.text = profile['biografia']?.toString() ?? '';
        _email = profile['email']?.toString();
        _profilePhoto = profile['foto_perfil']?.toString();
        _savingProfile = false;
      });
      widget.onProfileUpdated?.call(profile);
      _showMessage(
        'Perfil atualizado. A foto também foi atualizada na capa pública.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
      _showMessage(
        _errorMessage(error, 'Não foi possível salvar o perfil.'),
        error: true,
      );
    }
  }

  Future<void> _searchCep() async {
    if (_cepController.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      _showMessage('Informe um CEP válido.', error: true);
      return;
    }

    setState(() => _searchingCep = true);
    final result = await _addressService.searchCep(_cepController.text);
    if (!mounted) return;

    setState(() => _searchingCep = false);
    if (result == null) {
      _showMessage(
        'CEP não encontrado. Confira o número e tente novamente.',
        error: true,
      );
      return;
    }

    setState(() {
      _streetController.text = result['logradouro']?.toString() ?? '';
      _districtController.text = result['bairro']?.toString() ?? '';
      _cityController.text = result['localidade']?.toString() ?? '';
      _stateController.text = result['uf']?.toString() ?? '';
    });
  }

  Future<void> _saveAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;

    final address = AddressModel(
      idEndereco: _address?.idEndereco,
      cep: _cepController.text.trim(),
      rua: _streetController.text.trim(),
      numero: _numberController.text.trim(),
      bairro: _districtController.text.trim(),
      cidade: _cityController.text.trim(),
      estado: _stateController.text.trim(),
      latitude: _address?.latitude,
      longitude: _address?.longitude,
    );

    setState(() => _savingAddress = true);
    try {
      if (_address == null) {
        final createdAddress = await _addressService.createAddress(address);
        if (!mounted) return;
        setState(() {
          _setAddress(createdAddress);
          _addressError = null;
          _savingAddress = false;
        });
      } else {
        final success = await _addressService.updateAddress(address);
        if (!mounted) return;
        setState(() => _savingAddress = false);
        if (!success) {
          _showMessage('Não foi possível salvar o endereço.', error: true);
          return;
        }
        setState(() {
          _setAddress(address);
          _addressError = null;
        });
      }

      _showMessage('Endereço/região atualizado com sucesso.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingAddress = false);
      _showMessage(
        _errorMessage(error, 'Não foi possível salvar o endereço.'),
        error: true,
      );
    }
  }

  Future<void> _openFormalization() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PrestadorFormalizacaoView()),
    );
    if (result == true && mounted) await _loadProfile();
  }

  Future<void> _openMeiTrail() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const TrilhaMeiView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildAddressCard(),
          const SizedBox(height: 24),
          _buildBusinessSection(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações do perfil',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_profileError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _profileError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.secondaryYellow.withValues(
                        alpha: 0.3,
                      ),
                      child: _uploadingPhoto
                          ? const CircularProgressIndicator()
                          : ClipOval(
                              child:
                                  _profilePhoto == null ||
                                      _profilePhoto!.trim().isEmpty
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 46,
                                      color: AppTheme.prestadorAccent,
                                    )
                                  : Image.network(
                                      _profilePhoto!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person_outline,
                                        size: 46,
                                        color: AppTheme.prestadorAccent,
                                      ),
                                    ),
                            ),
                    ),
                    TextButton.icon(
                      onPressed: _uploadingPhoto ? null : _selectProfilePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Alterar foto de perfil e capa'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe seu nome.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _email,
                key: ValueKey(_email),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  helperText: 'O e-mail da conta não pode ser alterado aqui.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Descrição profissional',
                  hintText:
                      'Conte aos clientes sobre sua experiência e serviços.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingProfile || _uploadingPhoto
                      ? null
                      : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_savingProfile ? 'Salvando...' : 'Salvar perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _addressFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endereço / Região de atendimento',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'A cidade e o bairro cadastrados são exibidos no seu perfil público.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              if (_addressError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _addressError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'CEP'),
                      validator: (value) =>
                          value == null ||
                              value.replaceAll(RegExp(r'\D'), '').length != 8
                          ? 'Informe um CEP válido.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Buscar CEP',
                    onPressed: _searchingCep ? null : _searchCep,
                    icon: _searchingCep
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Rua'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe a rua.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número / complemento',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o número.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o bairro.'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe a cidade.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'UF'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe a UF.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingAddress || _addressError != null
                      ? null
                      : _saveAddress,
                  icon: _savingAddress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.location_on_outlined),
                  label: Text(
                    _savingAddress ? 'Salvando...' : 'Salvar endereço',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessSection() {
    final formalizado = _profile['selo_formalizado'] == true;
    final optanteMei = _profile['optante_mei'] == true;
    final status = _profile['status_validacao']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meu Negócio / MEI',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Formalização e ferramentas para organizar seu negócio.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: formalizado
                  ? Colors.green.withValues(alpha: 0.12)
                  : AppTheme.secondaryYellow.withValues(alpha: 0.3),
              child: Icon(
                formalizado ? Icons.verified : Icons.business_outlined,
                color: formalizado
                    ? Colors.green.shade700
                    : AppTheme.prestadorAccent,
              ),
            ),
            title: Text(
              formalizado
                  ? 'Prestador formalizado'
                  : 'Cadastrar CNPJ / Formalização',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              status == null
                  ? 'Cadastre seus dados fiscais ou atualize seu cadastro.'
                  : 'Status: $status${optanteMei ? ' · Optante pelo MEI' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openFormalization,
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.school_outlined, color: AppTheme.primaryBlue),
            ),
            title: const Text(
              'Vantagens do MEI e Simulador',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Veja os benefícios e simule os custos mensais.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openMeiTrail,
          ),
        ),
      ],
    );
  }
}
