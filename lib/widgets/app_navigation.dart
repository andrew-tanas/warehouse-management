import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/items_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class AppNavigation extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AppNavigation({
    Key? key,
    required this.child,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              if (index == selectedIndex) return;

              Widget page;
              switch (index) {
                case 0:
                  page = const DashboardScreen();
                  break;
                case 1:
                  page = const CustomersScreen();
                  break;
                case 2:
                  page = const ItemsScreen();
                  break;
                default:
                  page = const DashboardScreen();
              }

              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => page,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            backgroundColor: const Color(0xFF1E1E2C),
            unselectedIconTheme: const IconThemeData(color: Colors.white54, opacity: 1),
            selectedIconTheme: const IconThemeData(color: Color(0xFF6C63FF), opacity: 1),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.bold,
            ),
            extended: MediaQuery.of(context).size.width >= 800,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(AppLocalizations.of(context).translate('dashboard')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(AppLocalizations.of(context).translate('customers')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2),
                label: Text(AppLocalizations.of(context).translate('items')),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.language, color: Colors.white54),
                    onPressed: () {
                      Provider.of<LocaleProvider>(context, listen: false).toggleLocale();
                    },
                    tooltip: AppLocalizations.of(context).translate('language'),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
