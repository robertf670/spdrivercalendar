// Generates solid-color PNGs for every apple-touch-startup-image in web/index.html.
// Run from the repo root: dart run tool/generate_ios_splash.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _red = 0x01;
const _green = 0x75;
const _blue = 0xC2;

void main() {
  final html = File('web/index.html').readAsStringSync();
  final hrefs = RegExp(r'href="(splash/apple-splash-(\d+)-(\d+)\.png)"')
      .allMatches(html)
      .toList();
  if (hrefs.isEmpty) {
    stderr.writeln('No apple-splash PNG hrefs found in web/index.html');
    exitCode = 1;
    return;
  }

  Directory('web/splash').createSync(recursive: true);
  final written = <String>{};
  for (final match in hrefs) {
    final path = match.group(1)!;
    if (!written.add(path)) continue;
    final width = int.parse(match.group(2)!);
    final height = int.parse(match.group(3)!);
    File('web/$path').writeAsBytesSync(solidPng(width, height, _red, _green, _blue));
    stdout.writeln('Wrote $path (${width}x$height)');
  }
}

Uint8List solidPng(int width, int height, int r, int g, int b) {
  final rowBytes = 1 + width * 3;
  final raw = Uint8List(rowBytes * height);
  for (var y = 0; y < height; y++) {
    final row = y * rowBytes;
    raw[row] = 0;
    for (var x = 0; x < width; x++) {
      final i = row + 1 + x * 3;
      raw[i] = r;
      raw[i + 1] = g;
      raw[i + 2] = b;
    }
  }

  final compressed = Uint8List.fromList(ZLibEncoder().convert(raw));
  final ihdr = ByteData(13);
  ihdr.setUint32(0, width);
  ihdr.setUint32(4, height);
  ihdr.setUint8(8, 8);
  ihdr.setUint8(9, 2);

  final bytes = BytesBuilder();
  bytes.add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  _pngChunk(bytes, 'IHDR', ihdr.buffer.asUint8List());
  _pngChunk(bytes, 'IDAT', compressed);
  _pngChunk(bytes, 'IEND', Uint8List(0));
  return bytes.takeBytes();
}

void _pngChunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  final length = ByteData(4)..setUint32(0, data.length);
  out.add(length.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crcInput = Uint8List(typeBytes.length + data.length)
    ..setAll(0, typeBytes)
    ..setAll(typeBytes.length, data);
  final crc = ByteData(4)..setUint32(0, _crc32(crcInput));
  out.add(crc.buffer.asUint8List());
}

int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});
