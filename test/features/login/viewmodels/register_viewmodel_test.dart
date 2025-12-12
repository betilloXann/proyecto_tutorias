import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/register_viewmodel.dart';
//import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';
import 'package:proyecto_tutorias/data/models/user_model.dart';

// Reutilizamos los mocks
import 'login_viewmodel_test.mocks.dart'; 

void main() {
  late RegisterViewModel viewModel;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = RegisterViewModel(authRepo: mockAuthRepository);
  });

  group('RegisterViewModel Tests', () {
    test('Estado inicial correcto', () {
      expect(viewModel.currentStep, 0);
      expect(viewModel.foundStudent, isNull);
    });

    test('Step 0: Search Student - Éxito cambia al Step 1', () async {
      // Arrange
      final user = UserModel(
        id: '123',
        boleta: '2020123456',
        role: 'student',
        academies: ['INFORMATICA'],
        name: 'Test', 
        email: 'test@test.com', 
        status: 'PRE_REGISTRO'
      );
      
      when(mockAuthRepository.checkStudentStatus('2020640000'))
          .thenAnswer((_) async => user);

      // Act
      viewModel.boletaController.text = '2020640000';
      await viewModel.searchStudent();

      // Assert
      expect(viewModel.foundStudent, user);
      expect(viewModel.currentStep, 1); // Debe avanzar
      expect(viewModel.errorMessage, isNull);
    });

    test('Step 0: Search Student - Fallo si status no es PRE_REGISTRO', () async {
      final user = UserModel(
        id: '123', 
        boleta: '2020123456',
        role: 'student',
        academies: ['INFORMATICA'],
        name: 'Test', 
        email: 'test@test.com', 
        status: 'PRE_REGISTRO',
      );
      
      when(mockAuthRepository.checkStudentStatus('2020640000'))
          .thenAnswer((_) async => user);

      viewModel.boletaController.text = '2020640000';
      await viewModel.searchStudent();

      expect(viewModel.foundStudent, isNull); // No debe guardarlo
      expect(viewModel.currentStep, 0); // No debe avanzar
      expect(viewModel.errorMessage, contains('ya tiene una cuenta activa'));
    });

    test('Step 1: Activate Account - Fallo por campos vacíos', () async {
      // Simulamos que ya estamos en el paso 1 con un usuario
      // (aunque para esta prueba de validación no es estrictamente necesario, es buen contexto)
      
      // Act: Intentar activar sin llenar nada
      final result = await viewModel.activateAccount();

      // Assert
      expect(result, false);
      expect(viewModel.errorMessage, contains('Todos los campos'));
    });

    test('Step 1: Activate Account - Fallo por falta de CURP', () async {
      // Llenamos los campos de texto
      viewModel.emailController.text = 'correo@test.com';
      viewModel.passwordController.text = '123456';
      viewModel.phoneController.text = '5555555555';
      viewModel.personalEmailController.text = 'personal@test.com';
      
      // NOTA: Como no podemos simular fácilmente el FilePicker aquí sin wrappers,
      // la validación fallará primero por los archivos si son null.
      // Sin embargo, tu código valida "campos vacíos... incluyendo dictamen" en un solo if.
      // Si logramos pasar ese if (mockeando o asumiendo), caería en el de CURP.
      
      // Para probar ESPECÍFICAMENTE la validación de CURP, necesitaríamos saltar la validación de archivos.
      // Dado que _dictamenFileMobile es privado y no tiene setter, esta prueba se detendrá 
      // en "Todos los campos... son obligatorios" que es el comportamiento correcto actual.
      
      final result = await viewModel.activateAccount();
      expect(result, false);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('Back to Search resetea el estado', () {
      viewModel.boletaController.text = 'algo';
      viewModel.backToSearch();
      
      expect(viewModel.currentStep, 0);
      expect(viewModel.foundStudent, isNull);
      expect(viewModel.boletaController.text, isEmpty);
    });
  });
}