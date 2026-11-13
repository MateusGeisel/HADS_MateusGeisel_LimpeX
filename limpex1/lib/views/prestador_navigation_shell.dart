import 'package:flutter/material.dart';

import '../main.dart';

class PrestadorNavigationShell extends StatefulWidget {
  const PrestadorNavigationShell({
    super.key,
    required this.dashboard,
    required this.servicesAndAgenda,
    required this.profile,
    required this.onRefresh,
    required this.onLogout,
  });

  final Widget dashboard;
  final Widget servicesAndAgenda;
  final Widget profile;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  State<PrestadorNavigationShell> createState() =>
      _PrestadorNavigationShellState();
}

class _PrestadorNavigationShellState extends State<PrestadorNavigationShell> {
  int _selectedIndex = 0;
  bool _profileTabOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('LimpeX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: widget.onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          widget.dashboard,
          widget.servicesAndAgenda,
          if (_profileTabOpened) widget.profile else const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
          if (index == 2) _profileTabOpened = true;
        }),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.prestadorAccent,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Meus Serviços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Meu Perfil',
          ),
        ],
      ),
    );
  }
}
