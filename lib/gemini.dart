import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;


const GEMINI_PORT = 1965;

class Request {
  final String host;
  final String path;

  Request(this.host, this.path);

  Future<Response> send() async {
    final socket = await SecureSocket.connect(host, GEMINI_PORT, onBadCertificate: (cerificate) => true ); // FIXME: implement TOFU
    final url = 'gemini://' + host + path + '\r\n';
    developer.log('Sending Gemini reuest: ' + url);
    socket.write(url);
    final response = await Response.fromStream(socket);
    await socket.close();
    return response;
  }
}

class Response {
  final _Header _header;
  final String body; // FIXME: parse into ADT with MIME

  bool get success => _header.success;

  Response(this._header, this.body);

  static Future<Response> fromStream(Stream<Uint8List> stream) async {
    // FIXME: somehow handle binary and other formats based on response's MIME meta.
    final lines = await stream.map((list) => list.toList()).transform(utf8.decoder).transform(LineSplitter()).toList();
    final header = _Header.parse(lines[0]);
    return Response(header, lines.skip(1).join());
  }
}

class _Header {
  // Gemini response header
  final int code;
  final String meta;

  bool get success => code >= 20 && code < 30;

  _Header(this.code, this.meta);

  static _Header parse(String line) {
    final parts = line.split(' ');
    final code = int.parse(parts[0]);
    if (parts.length > 1) {
      return _Header(code, parts[1]);
    } else {
      return _Header(code, null);
    }
  }
}
