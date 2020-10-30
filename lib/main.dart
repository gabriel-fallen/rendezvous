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
const String notFound = 'Page not found';
const String serverError = 'Internal server error';

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller;
  String contents = ''; // FIXME: formatting and stuff...

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
          children: <Widget>[
            TextField(
              controller: _controller,
              onSubmitted: _loadPage,
            ),
            RichText(
              text: TextSpan(
                // style: DefaultTextStyle.of(context).style,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: contents,
                    style: TextStyle(fontWeight: FontWeight.bold)
                  )
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadPage(String page) async {
    final uri = Uri.parse(page);
    final request = new Request(uri.host, uri.path + uri.fragment);
    final response = await request.send();
    setState(() {
      contents = response.body;
    });
  }
}
