import 'package:pdf/widgets.dart' as pw;

void main() {
  var t = pw.Transform.rotateBox(angle: 1.5, child: pw.Text("A"));
  print(t.unconstrained);
}
