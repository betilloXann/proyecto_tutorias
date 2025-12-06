import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/login_viewmodel.dart';
import 'package:proyecto_tutorias/features/login/views/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock manual corregido para coincidir con la firma de AuthRepository
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

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(authRepository: mockAuthRepository);
  });

  // Helper para levantar la app con el Provider necesario
  Widget createWidget() {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        // Rutas dummy para que la navegación no falle
        routes: {
          '/home': (_) => const Scaffold(body: Text('HOME_SCREEN')),
          '/welcome': (_) => const Scaffold(body: Text('WELCOME_SCREEN')),
          '/recover': (_) => const Scaffold(body: Text('RECOVER_SCREEN')),
          '/activation': (_) => const Scaffold(body: Text('ACTIVATION_SCREEN')),
        },
        home: const LoginView(),
      ),
    );
  }

  testWidgets('Debe mostrar los campos de texto y el botón', (tester) async {
    await tester.pumpWidget(createWidget());

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Correo Personal'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('Al ingresar credenciales correctas, debe navegar a Home', (tester) async {
    // 1. Configurar Mock CON VALORES EXACTOS
    // Usamos los mismos strings que escribiremos abajo
    when(mockAuthRepository.signIn(email: 'profe@ipn.mx', password: '123456'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(createWidget());

    // 2. Interactuar
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo Personal'), 'profe@ipn.mx');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), '123456');

    // Tap en botón y esperar animaciones
    await tester.tap(find.text('Ingresar'));
    await tester.pump(); // Inicia proceso (loading)
    await tester.pumpAndSettle(); // Finaliza animaciones y navegación

    // 3. Verificar navegación
    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('Al fallar login, debe mostrar SnackBar con error', (tester) async {
    // 1. Configurar Mock para error CON VALORES EXACTOS
    // Usamos los mismos strings que escribiremos abajo
    when(mockAuthRepository.signIn(email: 'a', password: 'b'))
        .thenThrow(Exception('Error de red'));

    await tester.pumpWidget(createWidget());

    await tester.enterText(find.widgetWithText(TextFormField, 'Correo Personal'), 'a');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'b');
    await tester.tap(find.text('Ingresar'));

    await tester.pumpAndSettle();

    // 3. Verificar que sigue en la misma pantalla y muestra error
    expect(find.text('HOME_SCREEN'), findsNothing);
    expect(find.text('Error de red'), findsOneWidget); // Mensaje del SnackBar
  });
}