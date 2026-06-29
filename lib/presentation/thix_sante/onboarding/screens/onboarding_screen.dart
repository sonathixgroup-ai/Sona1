// 📁 lib/presentation/thix_sante/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import '../widgets/onboarding_item.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItemData> _pages = const [
    OnboardingItemData(
      title: 'Bienvenue sur THIX SANTÉ',
      description: 'Votre santé, notre priorité. Gérez votre parcours médical en toute simplicité.',
      icon: Icons.health_and_safety,
    ),
    OnboardingItemData(
      title: 'Suivi personnalisé',
      description: 'Symptômes, constantes, traitements : tout votre suivi santé réuni au même endroit.',
      icon: Icons.analytics,
    ),
    OnboardingItemData(
      title: 'Téléconsultation & Entraide',
      description: 'Consultez des médecins, échangez avec votre famille et gérez vos ordonnances en un clic.',
      icon: Icons.video_call,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingItem(
                    title: page.title,
                    description: page.description,
                    icon: page.icon,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onComplete();
                    },
                    child: const Text('Passer', style: TextStyle(fontSize: 13)),
                  ),
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        widget.onComplete();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                      style: TextStyle(fontSize: 13, color: Colors.green),
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

class OnboardingItemData {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingItemData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
