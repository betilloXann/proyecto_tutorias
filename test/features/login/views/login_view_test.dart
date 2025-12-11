import 'dart:convert';
//import 'dart:typed_data'; // Necesario para Uint8List
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
    if (email == 'error@ipn.mx') {
      throw Exception('Credenciales inválidas'); // Simular error
    }
    return null; // Simular éxito
  }
}

class TestAssetBundle extends CachingAssetBundle {
  // Un PNG de 1x1 pixel transparente en base64. 
  // Esto es válido para que Image.asset lo decodifique sin errores.
  final String _base64Png =
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return "Dummy String Content";
  }

  @override
  Future<ByteData> load(String key) async {
    // Decodificamos el base64 a bytes reales de imagen
    final Uint8List bytes = base64Decode(_base64Png);
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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Renderizado Inicial: Debe mostrar campos y botón', (tester) async {
    setScreenSize(tester);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byKey(const Key('login_email_input')), findsOneWidget);
    expect(find.byKey(const Key('login_password_input')), findsOneWidget);

    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('Login Exitoso: Debe navegar a /home', (tester) async {
    setScreenSize(tester);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 2. Llenar formulario
    await tester.enterText(find.byKey(const Key('login_email_input')), 'profe@ipn.mx');
    await tester.enterText(find.byKey(const Key('login_password_input')), '123');

    // 3. Cerrar teclado virtual
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // 4. Presionar botón
    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);

    await tester.pumpAndSettle(); // Esperar navegación

    // 5. Verificar navegación
    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('Login Fallido: Debe mostrar SnackBar con error', (tester) async {
    setScreenSize(tester);

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