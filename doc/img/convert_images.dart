import 'dart:io';

// ...........................................................................
void main() {
  final imagesDir = Directory('${projectRoot()}/doc/img');
  final dotFiles = imagesDir.listSync().where((file) {
    return file is File && file.path.endsWith('.dot');
  }).toList();

  for (final dotFile in dotFiles) {
    final dotFilePath = dotFile.path;
    final svgFilePath = dotFilePath.replaceAll('.dot', '.svg');

    // Run the 'dot' command to convert .dot to .svg
    final process =
        Process.runSync('dot', ['-Tsvg', dotFilePath, '-o', svgFilePath]);

    if (process.exitCode == 0) {
      print('Converted $dotFilePath to $svgFilePath');
    } else {
      print('Error converting $dotFilePath to SVG: ${process.stderr}');
    }
  }
}

// ...........................................................................
String? projectRoot() {
  var result = Directory.current;
  while (
      result.path != '/' && !File('${result.path}/pubspec.yaml').existsSync()) {
    result = result.parent;
  }

  return result.path;
}
