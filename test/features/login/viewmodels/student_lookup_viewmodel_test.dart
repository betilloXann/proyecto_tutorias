import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/student_lookup_viewmodel.dart';
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';
import 'package:proyecto_tutorias/data/models/user_model.dart';

// Genera el mock si no tienes uno global
@GenerateMocks([AuthRepository])
import 'login_viewmodel_test.mocks.dart';

void main() {
  late StudentLookupViewModel viewModel;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = StudentLookupViewModel(mockAuthRepository);
  });

  group('StudentLookupViewModel - Search Boleta', () {
    test('Estado inicial correcto', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.foundUser, isNull);
      expect(viewModel.isBoletaVerified, false);
    });

    test('Error si la boleta está vacía', () async {
      final result = await viewModel.searchStudent('');
      expect(result, false);
      expect(viewModel.errorMessage, 'Escribe una boleta');
    });

    test('Éxito: Usuario encontrado y en PRE_REGISTRO', () async {
      // Arrange
      final user = UserModel(
        id: '123', 
        name: 'Juan', 
        email: 'juan@test.com', 
        status: 'PRE_REGISTRO',
        boleta: '2020123456',
        role: 'student',
        academies: ['INFORMATICA']
        // Agrega otros campos requeridos por tu modelo
      );
      
      when(mockAuthRepository.checkStudentStatus('2020123456'))
          .thenAnswer((_) async => user);

      // Act
      final result = await viewModel.searchStudent('2020123456');

      // Assert
      expect(result, true);
      expect(viewModel.foundUser, user);
      expect(viewModel.isBoletaVerified, true);
      expect(viewModel.errorMessage, isNull);
    });

    test('Fallo: Usuario ya activado (status != PRE_REGISTRO)', () async {
      final user = UserModel(
        id: '123', 
        name: 'Activo',
        boleta: '',
        email: 'activo@test.com', 
        status: 'ACTIVO',
        role: 'student',
        academies: ['INFORMATICA'],
      );
      
      when(mockAuthRepository.checkStudentStatus('2020123456'))
          .thenAnswer((_) async => user);

      final result = await viewModel.searchStudent('2020123456');

      expect(result, false);
      expect(viewModel.errorMessage, contains('ya fue activada'));
    });

    test('Fallo: Usuario no existe (null)', () async {
      when(mockAuthRepository.checkStudentStatus('0000000000'))
          .thenAnswer((_) async => null);

      final result = await viewModel.searchStudent('0000000000');

      expect(result, false);
      expect(viewModel.errorMessage, contains('no encontrada'));
    });
  });

  group('StudentLookupViewModel - Validate CURP', () {
    // Un CURP válido genérico para pruebas
    const validCurp = 'PEPJ900101HDFRRA01';

    test('Fallo: Formato de CURP inválido (Regex)', () async {
      final result = await viewModel.validateCurp('INVALIDO');
      expect(result, false);
      expect(viewModel.errorMessage, contains('formato del CURP es inválido'));
    });

    test('Fallo: CURP ya registrado en BD', () async {
      when(mockAuthRepository.checkCurpExists(validCurp))
          .thenAnswer((_) async => true); // Existe

      final result = await viewModel.validateCurp(validCurp);

      expect(result, false);
      expect(viewModel.errorMessage, contains('ya está registrado'));
    });

    test('Éxito: CURP válido y no registrado', () async {
      when(mockAuthRepository.checkCurpExists(validCurp))
          .thenAnswer((_) async => false); // No existe

      final result = await viewModel.validateCurp(validCurp);

      expect(result, true);
      expect(viewModel.errorMessage, isNull);
    });
  });
}