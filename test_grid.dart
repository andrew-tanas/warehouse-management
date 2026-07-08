import 'package:pdf/widgets.dart' as pw;

void main() {
  var grid = pw.GridView(
    crossAxisCount: 4,
    children: [pw.Text("A"), pw.Text("B")],
  );
  print(grid);
}
