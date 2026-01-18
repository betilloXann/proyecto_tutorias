import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:cleartec_docx_template/cleartec_docx_template.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../data/models/enrollment_model.dart';
import 'package:flutter/foundation.dart';

class WordGeneratorService {

  Future<List<int>?> generateRecoveryAct({
    required String studentName,
    required String boleta,
    required List<EnrollmentModel> allEnrollments,
    String grupo = 'N/A',
  }) async {
    try {
      debugPrint('--- INICIO DEBUG WORD ---');

      // PASO 1
      debugPrint('1. Configurando fechas...');
      await initializeDateFormatting('es', null);

      // PASO 2
      debugPrint('2. Cargando asset...');
      final ByteData data = await rootBundle.load('assets/docs/acta_plantilla.docx');

      // PASO 3
      debugPrint('3. Copiando bytes manualmente...');
      // Usamos growable: true explícitamente para asegurar que sea modificable al 100%
      final List<int> bytes = data.buffer.asUint8List().toList(growable: true);
      debugPrint('   -> Bytes copiados: ${bytes.length}');

      // PASO 4
      debugPrint('4. Creando instancia DocxTemplate...');
      final docx = await DocxTemplate.fromBytes(bytes);

      // PASO 5
      debugPrint('5. Preparando Content...');
      final Content content = Content();
      //content.add(TextContent("dia", DateFormat('dd').format(now)));
      //content.add(TextContent("mes", DateFormat('MMMM', 'es').format(now).toUpperCase()));
      //content.add(TextContent("anio", DateFormat('yyyy').format(now)));

      // PASO 6
      debugPrint('6. Procesando ${allEnrollments.length} alumnos para la tabla...');
      final List<Content> filasDeLaTabla = []; // Esta lista es growable por defecto
      int contador = 1;

      for (var enrollment in allEnrollments) {
        debugPrint('   -> Procesando fila $contador: ${enrollment.subject}');
        final row = Content();

        row.add(TextContent("id", contador.toString()));
        row.add(TextContent("materia", enrollment.subject));
        row.add(TextContent("nombre_profesor", enrollment.professor.isNotEmpty ? enrollment.professor : "Sin Asignar"));
        debugPrint('   -> Procesando fila $contador: ${enrollment.professor}');
        row.add(TextContent("nombre_alumno", studentName));
        debugPrint('   -> Procesando fila $contador: $studentName');
        row.add(TextContent("boleta", boleta));
        debugPrint('   -> Procesando fila $contador: $boleta');

        // Lógica de calificación
        final calif = enrollment.finalGrade;
        final textoCalif = calif != null ? calif.toString() : "-";
        row.add(TextContent("calificacion", textoCalif));
        debugPrint('   -> Procesando fila $contador: $textoCalif');

        filasDeLaTabla.add(row);
        contador++;
      }

      // PASO 7
      debugPrint('7. Agregando ListContent al contenido principal...');
      // A veces el error viene aquí si la lista filasDeLaTabla fuera fija (que no lo es),
      // o si la librería intenta modificarla internamente.
      content.add(ListContent("materias", filasDeLaTabla));

      // PASO 8
      debugPrint('8. GENERANDO DOCUMENTO FINAL (Aquí suele fallar)...');
      final generatedBytes = await docx.generate(content);

      debugPrint('9. ¡ÉXITO! Documento generado.');
      debugPrint('--- FIN DEBUG WORD ---');

      return generatedBytes;

    } catch (e, stackTrace) {
      debugPrint('❌ Falla en el paso anterior. ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}