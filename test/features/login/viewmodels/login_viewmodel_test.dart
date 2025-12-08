import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/login_viewmodel.dart';
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';

// ESTA LÍNEA ES LA CLAVE: Indica que queremos generar un Mock de AuthRepository
@GenerateMocks([AuthRepository])
import 'login_viewmodel_test.mocks.dart'; // Este archivo aún no existe, se generará en el Paso 3

void main() {
  late LoginViewModel viewModel;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    // Inicializamos el Mock generado
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(authRepository: mockAuthRepository);
  });

  group('LoginViewModel Tests', () {
    test('Estado inicial correcto', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
    });

    test('login exitoso: debe retornar true y detener loading', () async {
      // 1. Arrange: Configuramos el mock para que responda con éxito
      when(mockAuthRepository.signIn(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => null); // Retorna null (void/User?) simulando éxito

      // 2. Act
      final futureResult = viewModel.login('test@ipn.mx', '123456');

      // Verificamos estado intermedio (loading debe ser true)
      expect(viewModel.isLoading, true);

      final result = await futureResult;

      // 3. Assert
      expect(result, true);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
    });

    test('login fallido: debe retornar false y guardar mensaje de error', () async {
      // 1. Arrange: Configuramos el mock para que lance error
      when(mockAuthRepository.signIn(email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(Exception('Credenciales incorrectas'));

      // 2. Act
      final result = await viewModel.login('test@ipn.mx', 'badpass');

      // 3. Assert
      expect(result, false);
      expect(viewModel.isLoading, false);
      // El ViewModel limpia el "Exception: ", así que esperamos solo el mensaje
      expect(viewModel.errorMessage, 'Credenciales incorrectas');
    });
  });
}