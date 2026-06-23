import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/firebase_options.dart';
import 'package:recipe_creator_ai/services/theme_controller.dart';
import 'package:recipe_creator_ai/theme/app_theme.dart';
import 'package:recipe_creator_ai/widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'Recipe Creator AI',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final themeController = ThemeController();
  await themeController.load();
  runApp(RecipeCreatorApp(themeController: themeController));
}

class RecipeCreatorApp extends StatelessWidget {
  const RecipeCreatorApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return AppThemeScope(
          controller: themeController,
          child: MaterialApp(
            title: 'Skillet',
            theme: buildAppTheme(themeController.current.colorScheme),
            home: const AuthGate(),
          ),
        );
      },
    );
  }
}

class AppThemeScope extends InheritedNotifier<ThemeController> {
  const AppThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in widget tree');
    return scope!.notifier!;
  }
}
