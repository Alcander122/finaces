// TutorialScreen.dart
import 'package:finances/core/data/providers/tutorial_provider.dart';
import 'package:finances/presentations/screens/Tutorial/widgets/tutorial_page_widget.dart';
import 'package:finances/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finances/presentations/theme/themes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.attach_money,
      'title': 'Registra tus ingresos',
      'description':
          'Agrega todos tus ingresos mensuales para tener un control total de tu dinero.',
      'color': Colors.green,
    },
    {
      'icon': Icons.remove_circle,
      'title': 'Controla tus gastos',
      'description':
          'Registra cada gasto diario y clasifícalo por categorías para entender dónde va tu dinero.',
      'color': Colors.red,
    },
    {
      'icon': FontAwesomeIcons.piggyBank,
      'title': 'Ahorra con metas',
      'description':
          'Define metas de ahorro y sigue tu progreso mes a mes. ¡Alcanza tus sueños financieros!',
      'color': Colors.orange,
    },
    {
      'icon': FontAwesomeIcons.chartLine,
      'title': 'Visualiza tu portafolio',
      'description':
          'Revisa gráficos e inversiones en tu portafolio personalizado. Todo en un solo lugar.',
      'color': Colors.purple,
    },
    {
      'icon': FontAwesomeIcons.calendarCheck,
      'title': 'Programa tus pagos',
      'description':
          'No olvides fechas importantes. Programa tus pagos y recibe recordatorios a tiempo.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.account_balance_wallet,
      'title': 'Resumen financiero',
      'description':
          'Verás aquí tu saldo disponible, ingresos y gastos totales del mes. Es tu dashboard principal.',
      'color': Colors.cyan,
    },
    {
      'icon': Icons.bar_chart,
      'title': 'Estadísticas detalladas',
      'description':
          'Analiza tus gastos por categoría, gráficas mensuales anuales o trimestral. Controla tu dinero con datos.',
      'color': Colors.pink,
    },
    {
      'icon': Icons.fingerprint,
      'title': 'Inicia sesión con tu huella',
      'description':
          'Accede fácilmente con tu huella digital. Activa esta opción desde tu perfil para mayor seguridad y comodidad.',
      'color': Colors.pink,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  /// Salta el tutorial → marca como visto **solo si era primera vez**
  void _skipTutorial() async {
    final hasSeen = ref.read(tutorialProvider).valueOrNull ?? false;

    if (!hasSeen) {
      await ref.read(tutorialNotifierProvider).markAsSeen();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  /// Finaliza el tutorial → marca como visto **solo si era primera vez**
  void _finishTutorial() async {
    final hasSeen = ref.read(tutorialProvider).valueOrNull ?? false;

    if (!hasSeen) {
      await ref.read(tutorialNotifierProvider).markAsSeen();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Themes.degradientLight, Themes.degradientDark],
          ),
        ),
        child: Column(
          children: [
            // Botón "Saltar"
            Padding(
              padding: const EdgeInsets.only(top: 60, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipTutorial,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Saltar',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del tutorial
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: TutorialPageWidget(
                      icon: page['icon'],
                      title: page['title'],
                      description: page['description'],
                      iconColor: page['color'],
                    ),
                  );
                },
              ),
            ),

            // Indicadores + botón
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return Container(
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),

                  // Botón Siguiente / Empezar
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _finishTutorial();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Empezar'
                            : 'Siguiente',
                        style: const TextStyle(
                          color: Themes.degradientDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
