import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importa tus clases reales
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/login_viewmodel.dart';
import 'package:proyecto_tutorias/features/login/views/login_view.dart';

// -------------------------------------------------------------------------
// 1. MOCKS MANUALES (Simplificados y Robustos)
// -------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<User?> signIn({required String email, required String password}) async {
    // Simulamos la lógica aquí para evitar problemas con 'when' y argumentos nombrados
    if (email == 'error@ipn.mx') {
      throw Exception('Credenciales inválidas'); // Simular error
    }
    return null; // Simular éxito (User? es null en tu implementación actual al loguear)
  }
}

class TestAssetBundle extends CachingAssetBundle {
  final String _svgDummy = '''
<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">
  <rect width="10" height="10" fill="transparent"/>
</svg>
''';

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _svgDummy;
  }

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = utf8.encode(_svgDummy);
    return ByteData.view(bytes.buffer);
  }
}

// -------------------------------------------------------------------------
// 2. PRUEBAS
// -------------------------------------------------------------------------

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(authRepository: mockAuthRepository);
  });

  Widget createTestWidget() {
    return DefaultAssetBundle(
      bundle: TestAssetBundle(),
      child: ChangeNotifierProvider<LoginViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          routes: {
            // Rutas dummy para verificar navegación
            '/home': (_) => const Scaffold(body: Text('HOME_SCREEN')),
            '/welcome': (_) => const Scaffold(body: Text('WELCOME_SCREEN')),
            '/recover': (_) => const Scaffold(body: Text('RECOVER_SCREEN')),
            '/activation': (_) => const Scaffold(body: Text('ACTIVATION_SCREEN')),
          },
          home: const LoginView(),
        ),
      ),
    );
  }

  // Helper para configurar la pantalla como un celular
  void setScreenSize(WidgetTester tester) {
    // Configura una resolución de 1080x2400 (celular moderno)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // Importante: resetear esto al terminar el test para no afectar otros
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Renderizado Inicial: Debe mostrar campos y botón', (tester) async {
    setScreenSize(tester); // 1. Ajustar pantalla

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byKey(const Key('login_email_input')), findsOneWidget);
    expect(find.byKey(const Key('login_password_input')), findsOneWidget);

    // Al ser la pantalla alta, el botón debería ser visible sin scroll
    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('Login Exitoso: Debe navegar a /home', (tester) async {
    setScreenSize(tester); // 1. Ajustar pantalla

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 2. Llenar formulario
    await tester.enterText(find.byKey(const Key('login_email_input')), 'profe@ipn.mx');
    await tester.enterText(find.byKey(const Key('login_password_input')), '123');

    // 3. Cerrar teclado virtual (buena práctica)
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // 4. Presionar botón (Como la pantalla es alta, ya no necesitamos ensureVisible obligatoriamente,
    // pero lo dejamos por seguridad si el teclado estorba)
    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);

    await tester.pumpAndSettle(); // Esperar navegación

    // 5. Verificar navegación
    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('Login Fallido: Debe mostrar SnackBar con error', (tester) async {
    setScreenSize(tester); // 1. Ajustar pantalla

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 2. Llenar formulario con credenciales de error
    await tester.enterText(find.byKey(const Key('login_email_input')), 'error@ipn.mx');
    await tester.enterText(find.byKey(const Key('login_password_input')), 'bad');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // 3. Presionar botón
    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);

    await tester.pumpAndSettle(); // Esperar SnackBar

    // 4. Verificar error
    expect(find.text('HOME_SCREEN'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });
}