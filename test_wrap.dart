import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';

void main() async {
  var pdf = pw.Document();
  pdf.addPage(pw.MultiPage(
    build: (context) => [
      pw.Wrap(
        children: List.generate(100, (i) => pw.Container(width: 50, height: 150, color: PdfColors.red)),
      )
    ]
  ));
  File('test.pdf').writeAsBytesSync(await pdf.save());
  print("Success");
}
