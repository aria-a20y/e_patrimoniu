import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/properties/properties_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/scanning/scanning_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/contracts/contracts_screen.dart';
import 'features/auctions/auctions_screen.dart';
import 'features/ai/ai_assistant_screen.dart';
import 'features/users/users_screen.dart';
import 'features/audit/audit_screen.dart';
import 'features/coming_soon_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  final List<_NavItem> _mainNav = [
    _NavItem(0, 'Dashboard', Icons.dashboard_rounded, Icons.dashboard_outlined),
    _NavItem(1, 'Bunuri Imobile', Icons.business_rounded, Icons.business_outlined),
    _NavItem(2, 'Documente', Icons.folder_rounded, Icons.folder_outlined),
    _NavItem(3, 'Scanare documente', Icons.document_scanner_rounded, Icons.document_scanner_outlined),
    _NavItem(4, 'Tranzacții', Icons.swap_horiz_rounded, Icons.swap_horiz_outlined),
    _NavItem(5, 'Contracte', Icons.description_rounded, Icons.description_outlined),
    _NavItem(6, 'Licitații online', Icons.gavel_rounded, Icons.gavel_outlined),
    _NavItem(7, 'Asistent AI', Icons.smart_toy_rounded, Icons.smart_toy_outlined),
    _NavItem(8, 'Utilizatori', Icons.people_rounded, Icons.people_outlined),
    _NavItem(9, 'Jurnal de audit', Icons.history_rounded, Icons.history_outlined),
  ];

  final List<_NavItem> _comingSoonNav = [
    _NavItem(10, 'Plăți', Icons.payment_rounded, Icons.payment_outlined),
    _NavItem(11, 'Integrare Ghișeul.ro', Icons.computer_rounded, Icons.computer_outlined),
    _NavItem(12, 'Integrare ANAF/SPV', Icons.account_balance_rounded, Icons.account_balance_outlined),
    _NavItem(13, 'Integrare ANCPI', Icons.map_rounded, Icons.map_outlined),
    _NavItem(14, 'Notificări automate', Icons.notifications_rounded, Icons.notifications_outlined),
    _NavItem(15, 'Rapoarte avansate', Icons.bar_chart_rounded, Icons.bar_chart_outlined),
    _NavItem(16, 'Portal public extins', Icons.public_rounded, Icons.public_outlined),
    _NavItem(17, 'Integrare registre', Icons.storage_rounded, Icons.storage_outlined),
  ];

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0: return DashboardScreen(onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1: return const PropertiesScreen();
      case 2: return const DocumentsScreen();
      case 3: return const ScanningScreen();
      case 4: return const TransactionsScreen();
      case 5: return const ContractsScreen();
      case 6: return const AuctionsScreen();
      case 7: return const AiAssistantScreen();
      case 8: return const UsersScreen();
      case 9: return const AuditScreen();
      default: return ComingSoonScreen(title: _getComingSoonTitle(_selectedIndex));
    }
  }

  String _getComingSoonTitle(int idx) {
    final found = _comingSoonNav.where((n) => n.index == idx).toList();
    return found.isNotEmpty ? found.first.label : 'Modul';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    if (isMobile) return _buildMobileLayout();
    return _buildDesktopLayout();
  }

  // ============================================================
  // DESKTOP LAYOUT - Sidebar + Content
  // ============================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final w = _sidebarExpanded ? 260.0 : 72.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
        child: Column(
          children: [
            // Logo & Toggle
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (_sidebarExpanded) ...[
                    const Icon(Icons.account_balance_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'e-Patrimoniu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      _sidebarExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Main nav
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._mainNav.map((item) => _buildNavTile(item)),
                  if (_sidebarExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'MODULE VIITOARE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white12),
                    ),
                  ],
                  ..._comingSoonNav.map((item) => _buildNavTile(item, comingSoon: true)),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // User info + logout
            _buildSidebarFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(_NavItem item, {bool comingSoon = false}) {
    final isSelected = _selectedIndex == item.index;
    return Tooltip(
      message: _sidebarExpanded ? '' : item.label,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = item.index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: _sidebarExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected
                    ? Colors.white
                    : comingSoon
                        ? Colors.white30
                        : Colors.white60,
                size: 20,
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : comingSoon
                              ? Colors.white30
                              : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Curând',
                      style: TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'Inter'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: _sidebarExpanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.greenLight.withValues(alpha: 0.3),
            child: Text(
              (user?.displayName?.isNotEmpty == true
                  ? user!.displayName![0]
                  : user?.email?[0] ?? 'U')
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.displayName ?? 'Utilizator',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
              onPressed: () => FirebaseAuth.instance.signOut(),
              tooltip: 'Deconectare',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppTheme.bgGrey,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _buildScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final item = [
      ..._mainNav,
      ..._comingSoonNav,
    ].firstWhere((n) => n.index == _selectedIndex, orElse: () => _mainNav[0]);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Icon(item.activeIcon, color: AppTheme.greenEmerald, size: 20),
          const SizedBox(width: 10),
          Text(
            item.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textGrey),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.greenEmerald,
            child: Text(
              (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                  ? FirebaseAuth.instance.currentUser!.displayName![0]
                  : 'U')
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT - Bottom nav + Drawer
  // ============================================================
  Widget _buildMobileLayout() {
    final mobileItems = _mainNav.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.greenDark,
        title: const Row(
          children: [
            Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('e-Patrimoniu', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildMobileDrawer(),
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.greenPale,
        destinations: mobileItems.map((item) => NavigationDestination(
          icon: Icon(item.icon, color: AppTheme.textGrey),
          selectedIcon: Icon(item.activeIcon, color: AppTheme.greenEmerald),
          label: item.label.split(' ').first,
        )).toList(),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text('e-Patrimoniu',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              ..._mainNav.map((item) => ListTile(
                leading: Icon(item.icon, color: _selectedIndex == item.index ? Colors.white : Colors.white60, size: 20),
                title: Text(item.label, style: TextStyle(
                  color: _selectedIndex == item.index ? Colors.white : Colors.white70,
                  fontFamily: 'Inter', fontSize: 14,
                  fontWeight: _selectedIndex == item.index ? FontWeight.w600 : FontWeight.w400,
                )),
                tileColor: _selectedIndex == item.index ? Colors.white10 : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  setState(() => _selectedIndex = item.index);
                  Navigator.pop(context);
                },
              )),
              const Divider(color: Colors.white12),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('MODULE VIITOARE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ),
              ..._comingSoonNav.map((item) => ListTile(
                leading: Icon(item.icon, color: Colors.white30, size: 20),
                title: Text(item.label, style: const TextStyle(color: Colors.white30, fontFamily: 'Inter', fontSize: 13)),
                trailing: const Text('Curând', style: TextStyle(color: Colors.white30, fontSize: 10)),
                onTap: () {
                  setState(() => _selectedIndex = item.index);
                  Navigator.pop(context);
                },
              )),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.white60, size: 20),
                title: const Text('Deconectare', style: TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 14)),
                onTap: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final String label;
  final IconData activeIcon;
  final IconData icon;
  const _NavItem(this.index, this.label, this.activeIcon, this.icon);
}
