import 'dart:io';
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
    final response = await socket.map((list) => list.map((e) => e).toList()).transform(utf8.decoder).join();
    await socket.close();
    return new Response(response);
  }
}

class Response {
  final String body; // FIXME: parse into ADT with MIME

  Response(this.body);
}
