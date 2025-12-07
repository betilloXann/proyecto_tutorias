import 'dart:convert';
//import 'dart:typed_data';

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
// 1. MOCKS
// -------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<User?> signIn({required String email, required String password}) {
    return super.noSuchMethod(
      Invocation.method(#signIn, [], {#email: email, #password: password}),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }
}

/// Mock de AssetBundle corregido para flutter_svg moderno.
/// Devuelve siempre un SVG XML válido, tanto en String como en Bytes.
class TestAssetBundle extends CachingAssetBundle {
  // Un SVG real, válido y simple (un cuadrado transparente de 10x10)
  // Es CRUCIAL incluir el xmlns para que el parser estricto no falle.
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
    // AQUÍ ESTABA EL ERROR: Antes devolvíamos un PNG.
    // Ahora convertimos el String SVG a bytes UTF-8 para que el loader
    // binario también reciba un SVG válido.
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

  testWidgets('Renderizado Inicial: Debe mostrar campos y botón', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle(); // Esperar a que el SVG cargue y se renderice

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byKey(const Key('login_email_input')), findsOneWidget);
    expect(find.byKey(const Key('login_password_input')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);
  });

  testWidgets('Login Exitoso: Debe navegar a /home', (tester) async {
    when(mockAuthRepository.signIn(email: 'profe@ipn.mx', password: '123'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle(); // Importante: esperar carga inicial completa

    await tester.enterText(find.byKey(const Key('login_email_input')), 'profe@ipn.mx');
    await tester.enterText(find.byKey(const Key('login_password_input')), '123');

    await tester.tap(find.byKey(const Key('login_button')));

    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('Login Fallido: Debe mostrar SnackBar con error', (tester) async {
    when(mockAuthRepository.signIn(email: 'error@ipn.mx', password: 'bad'))
        .thenThrow(Exception('Credenciales inválidas'));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle(); // Importante: esperar carga inicial completa

    await tester.enterText(find.byKey(const Key('login_email_input')), 'error@ipn.mx');
    await tester.enterText(find.byKey(const Key('login_password_input')), 'bad');

    await tester.tap(find.byKey(const Key('login_button')));

    // Esperar a que ocurra el ciclo de error y aparezca el SnackBar
    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });
}