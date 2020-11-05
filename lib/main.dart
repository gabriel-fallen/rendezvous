import 'dart:developer' as developer;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:rendezvous/gemini.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rendezvous',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// Some constants
const String notFound = 'Page not found\n';
const String serverError = 'Internal server error\n';

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller;
  List<TextSpan> _contents;

  // navigation state
  List<String> _history = [];
  int _nredirects = 0;


  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _loadPage,
                  ),
                )
              ],
            ),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: RichText(
                  overflow: TextOverflow.visible,
                  text: TextSpan(
                    // style: DefaultTextStyle.of(context).style,
                    style: TextStyle(color: Colors.black, fontSize: _baseFontSize),
                    children: _contents
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _loadPage(String page) async {
    final uri = _resolve(page);
    // developer.log('_loadPage: page = "' + page + '"');
    // developer.log('_loadPage: uri = "' + uri.toString() + '"');
    if (uri.host.isEmpty) {
      setState(() {
        _contents = [TextSpan(text: 'Invalid host name', style: TextStyle(color: Colors.red, fontSize: 16))];
      });
      return;
    }

    final request = new Request(uri.host, uri.path + uri.fragment);
    final response = await request.send();

    // handle redirect
    if (response.redirect) {
      if (_nredirects < 5) {
        _nredirects++;
        _loadPage(response.meta); // will finish asynchronously
        return;
      }

      // report too many redirects
      setState(() {
        _contents = [TextSpan(text: 'Too many redirects', style: TextStyle(color: Colors.red, fontSize: 16))];
      });
      return;
    }

    // no redirects
    _nredirects = 0;
    setState(() {
      if (!response.success) {
        _contents = [
          TextSpan(text: serverError, style: TextStyle(color: Colors.red, fontSize: 16)),
          TextSpan(text: 'Status code: ' + response.code.toString() + '\n' + response.meta),
        ];
        return;
      }

      _controller.text = response.url;
      _history.add(response.url);
      if (response.body is Gemini)
        _contents = _present(response.body as Gemini);
      else
        _contents = [TextSpan(text: 'Unknown format', style: TextStyle(color: Colors.red, fontSize: 16))];
    });
  }

  Uri _resolve(String page) {
    var uri = Uri.parse(page);
    if (!uri.isAbsolute) {
      final base = Uri.parse(_history.isNotEmpty ? _history.last : '');
      uri = base.resolve(page);
    }
    return uri;
  }

  void _navigateBack() {
    if (_history.isEmpty) return; // noop

    final url = _history.last;
    _history.removeLast();
    _loadPage(url);
  }

  List<TextSpan> _present(Gemini page) {
    final spans = <TextSpan>[];
    for (var line in page.contents) {
      if      (line is GeminiText)         spans.add(TextSpan(text: line.line + '\n'));
      else if (line is GeminiLink)         spans.add(_buildLink(line));
      else if (line is GeminiHeader1)      spans.add(TextSpan(text: line.line + '\n', style: _header1Style));
      else if (line is GeminiHeader2)      spans.add(TextSpan(text: line.line + '\n', style: _header2Style));
      else if (line is GeminiHeader3)      spans.add(TextSpan(text: line.line + '\n', style: _header3Style));
      else if (line is GeminiPreformatted) spans.add(TextSpan(text: line.line + '\n', style: _preStyle));
      else if (line is GeminiQuote)        spans.add(TextSpan(text: line.line + '\n', style: _quoteStyle));
      else if (line is GeminiListItem)     spans.add(TextSpan(text: '* ' + line.line + '\n'));
      else                                 spans.add(TextSpan(text: line.line + '\n'));
    }
    return spans;
  }

  TextSpan _buildLink(GeminiLink gl) {
    return TextSpan(
      text: gl.line + '\n',
      style: _linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => _loadPage(gl.url)
    );
  }

  static const _linkStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
    decorationColor: Colors.blue,
  );

  static const _baseFontSize = 14.0;
  static const _header1Style = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const _header2Style = TextStyle(fontSize: 20, fontStyle: FontStyle.italic);
  static const _header3Style = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const _preStyle = TextStyle(fontFamily: 'Roboto Mono');
  static const _quoteStyle = TextStyle(fontStyle: FontStyle.italic);
}
