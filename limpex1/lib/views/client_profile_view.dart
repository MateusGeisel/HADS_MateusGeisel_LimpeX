import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';
import '../services/address_service.dart';
import '../services/profile_service.dart';
import '../services/upload_service.dart';

class ClientProfileView extends StatefulWidget {
  const ClientProfileView({
    super.key,
    required this.user,
    required this.solicitacoes,
    required this.carregandoSolicitacoes,
    this.cancelandoSolicitacaoId,
    required this.onRefreshSolicitacoes,
    required this.podeCancelarSolicitacao,
    required this.onCancelarSolicitacao,
    required this.onAvaliarSolicitacao,
    this.onProfileUpdated,
    this.profileService,
    this.addressService,
  });

  final UserModel user;
  final List<dynamic> solicitacoes;
  final bool carregandoSolicitacoes;
  final int? cancelandoSolicitacaoId;
  final Future<void> Function() onRefreshSolicitacoes;
  final bool Function(Map<String, dynamic>) podeCancelarSolicitacao;
  final Future<void> Function(Map<String, dynamic>) onCancelarSolicitacao;
  final Future<void> Function(Map<String, dynamic>) onAvaliarSolicitacao;
  final ValueChanged<Map<String, dynamic>>? onProfileUpdated;
  final ProfileService? profileService;
  final AddressService? addressService;

  @override
  State<ClientProfileView> createState() => _ClientProfileViewState();
}

class _ClientProfileViewState extends State<ClientProfileView> {
  late final ProfileService _profileService;
  late final AddressService _addressService;
  final _profileFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  AddressModel? _address;
  String? _email;
  String? _profilePhoto;
  String? _profileError;
  String? _addressError;
  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _savingAddress = false;
  bool _searchingCep = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
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
      _loadingProfile = true;
      _profileError = null;
      _addressError = null;
    });

    try {
      final profile = await _profileService.getProfile();
      _nameController.text = profile['nome']?.toString() ?? '';
      _phoneController.text = profile['telefone']?.toString() ?? '';
      _email = profile['email']?.toString();
      _profilePhoto = profile['foto_perfil']?.toString();
    } catch (error) {
      _profileError = _errorMessage(
        error,
        'Não foi possível carregar os dados do perfil.',
      );
    }

    try {
      final addresses = await _addressService.getAddresses();
      _setAddress(addresses.isEmpty ? null : addresses.first);
    } catch (error) {
      _addressError = _errorMessage(
        error,
        'Não foi possível carregar o endereço.',
      );
    }

    if (mounted) setState(() => _loadingProfile = false);
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
      final profile = await _profileService.updateProfile(
        nome: _nameController.text.trim(),
        telefone: _phoneController.text.trim(),
        fotoPerfil: _profilePhoto,
      );
      if (!mounted) return;
      setState(() {
        _nameController.text = profile['nome']?.toString() ?? '';
        _phoneController.text = profile['telefone']?.toString() ?? '';
        _email = profile['email']?.toString();
        _profilePhoto = profile['foto_perfil']?.toString();
        _savingProfile = false;
      });
      widget.onProfileUpdated?.call(profile);
      _showMessage('Perfil atualizado com sucesso.');
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

      if (!mounted) return;
      if (_address == null) {
        _showMessage('Não foi possível salvar o endereço.', error: true);
        return;
      }
      _showMessage('Endereço salvo com sucesso.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingAddress = false);
      _showMessage(
        _errorMessage(error, 'Não foi possível salvar o endereço.'),
        error: true,
      );
    }
  }

  List<Map<String, dynamic>> _requestsFor(Set<String> statuses) => widget
      .solicitacoes
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .where((item) => statuses.contains(item['status']?.toString()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Perfil'),
                Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Meus Serviços',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildProfileTab(), _buildServicesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildProfileSettings(),
          const SizedBox(height: 16),
          _buildAddressSettings(),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_loadingProfile) const LinearProgressIndicator(minHeight: 2),
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
                      radius: 46,
                      backgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.1,
                      ),
                      child: _uploadingPhoto
                          ? const CircularProgressIndicator()
                          : ClipOval(
                              child:
                                  _profilePhoto == null ||
                                      _profilePhoto!.trim().isEmpty
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 44,
                                      color: AppTheme.primaryBlue,
                                    )
                                  : Image.network(
                                      _profilePhoto!,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person_outline,
                                        size: 44,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                            ),
                    ),
                    TextButton.icon(
                      onPressed: _uploadingPhoto ? null : _selectProfilePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Alterar foto'),
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
                  helperText: 'O e-mail não pode ser alterado nesta tela.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 16),
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

  Widget _buildAddressSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _addressFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _address == null ? 'Adicionar endereço' : 'Meu endereço',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Usamos esse endereço para facilitar suas solicitações de serviço.',
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

  Widget _buildServicesTab() {
    final abertos = _requestsFor({'PENDENTE'});
    final andamento = _requestsFor({'ACEITO', 'EM_ANDAMENTO'});
    final concluidos = _requestsFor({'CONCLUIDO'});
    final encerrados = _requestsFor({'CANCELADO', 'RECUSADO'});

    return RefreshIndicator(
      onRefresh: widget.onRefreshSolicitacoes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (widget.carregandoSolicitacoes && widget.solicitacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          _buildRequestGroup(
            'Solicitações em aberto',
            'Aguardando resposta do prestador',
            abertos,
          ),
          _buildRequestGroup(
            'Serviços em andamento',
            'Serviços aceitos ou em execução',
            andamento,
          ),
          _buildRequestGroup(
            'Serviços concluídos',
            'Histórico dos serviços finalizados',
            concluidos,
          ),
          if (encerrados.isNotEmpty)
            _buildRequestGroup(
              'Cancelados ou recusados',
              'Solicitações encerradas sem conclusão',
              encerrados,
            ),
        ],
      ),
    );
  }

  Widget _buildRequestGroup(
    String title,
    String subtitle,
    List<Map<String, dynamic>> requests,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  requests.length.toString(),
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nenhum serviço nesta seção.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final request in requests) _buildRequestCard(request),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? 'PENDENTE';
    final id = int.tryParse(request['id_solicitacao']?.toString() ?? '');
    final podeCancelar = widget.podeCancelarSolicitacao(request);
    final cancelando = id != null && id == widget.cancelandoSolicitacaoId;
    final avaliada = request['avaliada'] == true;
    final podeAvaliar = status == 'CONCLUIDO' && !avaliada && id != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(
                    Icons.cleaning_services_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request['nome_servico']?.toString() ??
                        request['nome_categoria']?.toString() ??
                        'Serviço',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),
            if (request['nome_prestador'] != null)
              Text('Prestador: ${request['nome_prestador']}'),
            Text(
              'Data: ${_formatDate(request['data_agendamento'])}'
              '${request['horario_agendamento'] == null ? '' : ' às ${request['horario_agendamento']}'}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (status == 'PENDENTE' || status == 'ACEITO') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: podeCancelar && !cancelando
                      ? () => widget.onCancelarSolicitacao(request)
                      : null,
                  icon: cancelando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar solicitação'),
                ),
              ),
              if (!podeCancelar)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'O cancelamento deve ser feito com pelo menos 24 horas de antecedência.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
            ],
            if (status == 'CONCLUIDO' && avaliada) ...[
              const SizedBox(height: 8),
              _buildReview(request),
            ],
            if (podeAvaliar) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onAvaliarSolicitacao(request),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Avaliar serviço'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReview(Map<String, dynamic> request) {
    final rating =
        int.tryParse(request['avaliacao_nota']?.toString() ?? '') ?? 0;
    final comment = request['avaliacao_comentario']?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              Icon(
                star <= rating ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber.shade700,
              ),
            const SizedBox(width: 6),
            Text('$rating/5'),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status) {
      'CONCLUIDO' => Colors.green.shade700,
      'ACEITO' || 'EM_ANDAMENTO' => AppTheme.primaryBlue,
      'CANCELADO' || 'RECUSADO' => Colors.grey.shade700,
      _ => Colors.orange.shade800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'PENDENTE' => 'ABERTO',
    'ACEITO' => 'AGENDADO',
    'EM_ANDAMENTO' => 'EM ANDAMENTO',
    'CONCLUIDO' => 'CONCLUÍDO',
    'CANCELADO' => 'CANCELADO',
    'RECUSADO' => 'RECUSADO',
    _ => status,
  };

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Não informada';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
