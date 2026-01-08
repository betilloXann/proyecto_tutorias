import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:docx_template/docx_template.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:developer' as developer;

class WordGeneratorService {
  
  /// Genera los bytes del archivo .docx con los datos rellenos
  Future<List<int>?> generateRecoveryAct({
    required String studentName,
    required String boleta,
    required String subjectName,
    required String professorName,
    required String status, // 'ACREDITADO' o 'NO_ACREDITADO'
    String grupo = 'N/A', // Opcional si no tienes el dato a la mano
  }) async {
    try {
      // 1. Inicializar formato de fecha en español
      await initializeDateFormatting('es_ES', null);
      final now = DateTime.now();
      
      // 2. Cargar la plantilla desde los assets
      final ByteData data = await rootBundle.load('assets/docs/acta_plantilla.docx');
      final List<int> bytes = data.buffer.asUint8List();

      final docx = await DocxTemplate.fromBytes(bytes);

      // 3. Preparar el contenido (Content)
      final Content content = Content();

      // Fechas
      content.add(TextContent("dia", DateFormat('dd').format(now)));
      content.add(TextContent("mes", DateFormat('MMMM', 'es_ES').format(now).toUpperCase()));
      content.add(TextContent("anio", DateFormat('yyyy').format(now)));

      // Datos del Alumno y Materia
      content.add(TextContent("nombre_alumno", studentName));
      content.add(TextContent("boleta", boleta));
      content.add(TextContent("grupo", grupo));
      content.add(TextContent("materia", subjectName));
      content.add(TextContent("nombre_profesor", professorName));

      // Lógica de las X
      if (status == 'ACREDITADO') {
        content.add(TextContent("marca_acreditado", "X"));
        content.add(TextContent("marca_no_acreditado", ""));
      } else if (status == 'NO_ACREDITADO') {
        content.add(TextContent("marca_acreditado", ""));
        content.add(TextContent("marca_no_acreditado", "X"));
      } else {
        // Limpiar ambas si es otro estado
        content.add(TextContent("marca_acreditado", ""));
        content.add(TextContent("marca_no_acreditado", ""));
      }

      // 4. Generar el documento relleno
      final generatedBytes = await docx.generate(content);
      return generatedBytes;

    } catch (e, stackTrace) {
  developer.log(
    'Error generando Word',
    error: e,
    stackTrace: stackTrace,
  );
  return null;
    }
  }
}