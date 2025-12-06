import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';

class PdfGeneratorService {

  // AHORA RECIBIMOS LOS DATOS ESPECÍFICOS DE LA MATERIA
  Future<void> generarBitacora({
    required UserModel user,
    required String materia,
    required String profesor,
    required String horario,
    required String salon,
    required String academia, // <--- Importante para tu duda
  }) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO ---
              pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("INSTITUTO POLITÉCNICO NACIONAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                              pw.Text("UPIICSA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                              pw.Text("DEPARTAMENTO DE TUTORÍAS", style: pw.TextStyle(fontSize: 10)),
                            ]
                        ),
                        pw.Text("REPORTE MENSUAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      ]
                  )
              ),

              pw.SizedBox(height: 20),

              // --- DATOS DEL ALUMNO ---
              pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Alumno:", user.name),
                        pw.SizedBox(height: 5),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoRow("Boleta:", user.boleta),
                              // AQUÍ USAMOS LA ACADEMIA ESPECÍFICA DE ESTA MATERIA
                              _buildInfoRow("Academia:", academia),
                            ]
                        ),
                        pw.Divider(),
                        _buildInfoRow("Unidad de Aprendizaje:", materia),
                        pw.SizedBox(height: 5),
                        _buildInfoRow("Profesor Tutor:", profesor),
                        pw.SizedBox(height: 5),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoRow("Horario:", horario),
                              _buildInfoRow("Salón:", salon),
                            ]
                        ),
                      ]
                  )
              ),

              pw.SizedBox(height: 20),

              // --- TABLA (Igual que antes) ---
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 35,
                headers: ['No.', 'Fecha', 'Hora Entrada', 'Hora Salida', 'Firma'],
                data: List<List<String>>.generate(8, (index) => ['${index + 1}', '', '', '', '']),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bitacora_$materia.pdf', // El nombre del archivo cambia según la materia
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: "$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: value),
        ])
    );
  }
}