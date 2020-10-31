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
    final path = this.path.startsWith('/') ? this.path : '/' + this.path;
    final url = 'gemini://' + host + path + '\r\n';
    developer.log('Sending Gemini reuest: ' + url);
    socket.write(url);
    final response = await Response.fromStream(socket);
    response.url = url.trim();
    await socket.close();
    return response;
  }
}

class Response {
  String url; // for information purposes
  final _Header _header;
  final Body body;

  int get code => _header.code;
  String get meta => _header.meta;
  bool get success => _header.success;

  Response(this._header, this.body);

  static Future<Response> fromStream(Stream<Uint8List> stream) async {
    // FIXME: somehow handle binary and other formats based on response's MIME meta.
    final lines = await stream.map((list) => list.toList()).transform(utf8.decoder).transform(LineSplitter()).toList();
    final header = _Header.parse(lines[0]);
    if (header.success) {
      final body = Gemini.parse(lines.skip(1));
      body.mime = header.meta;
      return Response(header, body);
    }
    return Response(header, null);
  }
}

class _Header {
  // Gemini response header
  final int code;
  final String meta;

  bool get success => _success(code);

  _Header(this.code, this.meta);

  static _Header parse(String line) {
    final spaceIndex = line.indexOf(new RegExp(r'\s+'));
    final firstSpace = spaceIndex > 0 ? spaceIndex : line.length;
    final code = int.parse(line.substring(0, firstSpace));
    if (spaceIndex > 0) {
      return _Header(code, line.substring(firstSpace).trim());
    } else {
      return _Header(code, _success(code) ? 'text/gemini; charset=utf-8' : null);
    }
  }

  static bool _success(int code) => code >= 20 && code < 30;
}

abstract class Body {
  String get mime;
}

class RawData extends Body {
  final String mime;
  final Uint8List data;

  RawData(this.mime, this.data);
}

class Gemini extends Body {
  String mime;
  final List<GeminiLine> contents;

  Gemini(this.contents);

  static Gemini parse(Iterable<String> lines) {
    final contents = <GeminiLine>[];
    bool preformatted = false;
    for (var line in lines) {
      if (preformatted) {
        if (line.startsWith('```')) {
          preformatted = false;
          continue;
        }
        contents.add(GeminiPreformatted(line));
      } else {
        if      (line.startsWith('=>'))  contents.add(GeminiLink.parse(line.substring(2).trim()));
        else if (line.startsWith('###')) contents.add(GeminiHeader3(   line.substring(3).trim()));
        else if (line.startsWith('##'))  contents.add(GeminiHeader2(   line.substring(2).trim()));
        else if (line.startsWith('#'))   contents.add(GeminiHeader1(   line.substring(1).trim()));
        else if (line.startsWith('*'))   contents.add(GeminiListItem(  line.substring(1).trim()));
        else if (line.startsWith('>'))   contents.add(GeminiQuote(     line.substring(1).trim()));
        else if (line.startsWith('```')) preformatted = true; // FIXME: handle "alt" text for preformatted lines
        else                             contents.add(GeminiText(line.trim()));
      }
    }

    return Gemini(contents);
  }
}

abstract class GeminiLine {
  final String line;
  GeminiLine(this.line);
}

class GeminiLink extends GeminiLine {
  final String url;
  GeminiLink(String url, String title) : url = url, super(title);

  static GeminiLink parse(String line) {
    final spaceIndex = line.indexOf(new RegExp(r'\s+'));
    final firstSpace = spaceIndex > 0 ? spaceIndex : line.length;
    final url = line.substring(0, firstSpace);
    final title = spaceIndex > 0 ? line.substring(firstSpace).trim() : url;
    return GeminiLink(url, title);
  }
}

class GeminiText extends GeminiLine {
  GeminiText(String line) : super(line);
}

class GeminiPreformatted extends GeminiLine {
  GeminiPreformatted(String line) : super(line);
}

class GeminiHeader1 extends GeminiLine {
  GeminiHeader1(String line) : super(line);
}

class GeminiHeader2 extends GeminiLine {
  GeminiHeader2(String line) : super(line);
}

class GeminiHeader3 extends GeminiLine {
  GeminiHeader3(String line) : super(line);
}

class GeminiListItem extends GeminiLine {
  GeminiListItem(String line) : super(line);
}

class GeminiQuote extends GeminiLine {
  GeminiQuote(String line) : super(line);
}
