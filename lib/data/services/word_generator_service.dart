import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:cleartec_docx_template/cleartec_docx_template.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:developer' as developer;
import '../../data/models/enrollment_model.dart';

class WordGeneratorService {

  Future<List<int>?> generateRecoveryAct({
    required String studentName,
    required String boleta,
    required List<EnrollmentModel> allEnrollments,
    String grupo = 'N/A',
  }) async {
    try {
      print('--- INICIO DEBUG WORD ---');

      // PASO 1
      print('1. Configurando fechas...');
      await initializeDateFormatting('es', null);
      final now = DateTime.now();

      // PASO 2
      print('2. Cargando asset...');
      final ByteData data = await rootBundle.load('assets/docs/acta_plantilla.docx');

      // PASO 3
      print('3. Copiando bytes manualmente...');
      // Usamos growable: true explícitamente para asegurar que sea modificable al 100%
      final List<int> bytes = data.buffer.asUint8List().toList(growable: true);
      print('   -> Bytes copiados: ${bytes.length}');

      // PASO 4
      print('4. Creando instancia DocxTemplate...');
      final docx = await DocxTemplate.fromBytes(bytes);

      // PASO 5
      print('5. Preparando Content...');
      final Content content = Content();
      //content.add(TextContent("dia", DateFormat('dd').format(now)));
      //content.add(TextContent("mes", DateFormat('MMMM', 'es').format(now).toUpperCase()));
      //content.add(TextContent("anio", DateFormat('yyyy').format(now)));

      // PASO 6
      print('6. Procesando ${allEnrollments.length} alumnos para la tabla...');
      final List<Content> filasDeLaTabla = []; // Esta lista es growable por defecto
      int contador = 1;

      for (var enrollment in allEnrollments) {
        print('   -> Procesando fila $contador: ${enrollment.subject}');
        final row = Content();

        row.add(TextContent("id", contador.toString()));
        row.add(TextContent("materia", enrollment.subject));
        row.add(TextContent("nombre_profesor", enrollment.professor.isNotEmpty ? enrollment.professor : "Sin Asignar"));
        print('   -> Procesando fila $contador: ${enrollment.professor}');
        row.add(TextContent("nombre_alumno", studentName));
        print('   -> Procesando fila $contador: ${studentName}');
        row.add(TextContent("boleta", boleta));
        print('   -> Procesando fila $contador: ${boleta}');

        // Lógica de calificación
        final calif = enrollment.finalGrade;
        final textoCalif = calif != null ? calif.toString() : "-";
        row.add(TextContent("calificacion", textoCalif));
        print('   -> Procesando fila $contador: ${textoCalif}');

        filasDeLaTabla.add(row);
        contador++;
      }

      // PASO 7
      print('7. Agregando ListContent al contenido principal...');
      // A veces el error viene aquí si la lista filasDeLaTabla fuera fija (que no lo es),
      // o si la librería intenta modificarla internamente.
      content.add(ListContent("materias", filasDeLaTabla));

      // PASO 8
      print('8. GENERANDO DOCUMENTO FINAL (Aquí suele fallar)...');
      final generatedBytes = await docx.generate(content);

      print('9. ¡ÉXITO! Documento generado.');
      print('--- FIN DEBUG WORD ---');

      return generatedBytes;

    } catch (e, stackTrace) {
      print('❌ Falla en el paso anterior. ERROR: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}