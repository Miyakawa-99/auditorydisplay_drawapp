import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart';
import 'Painter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert' show json;
import "package:http/http.dart" as http;
import 'package:http/io_client.dart';
import 'dart:io' as io;

// GoogleSignIn _googleSignIn = new GoogleSignIn(
//   scopes: <String>[
//     DriveApi.DriveFileScope,
//     DriveApi.DriveAppdataScope,
//   ],
// );
GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

/*
 * ペイントページ
 */
class PaintPage extends StatefulWidget {
  @override
  _PaintPageState createState() => _PaintPageState();
}

/*
 * ペイント　ステート
 */
class _PaintPageState extends State<PaintPage> {
  // コントローラ
  PaintController _controller = PaintController();
  GoogleSignInAccount _currentUser;
  String _contactText;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetContact();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleGetContact() async {
    setState(() {
      _contactText = "Loading contact info...";
    });
    final http.Response response = await http.get(
      'https://people.googleapis.com/v1/people/me/connections'
      '?requestMask.includeField=person.names',
      headers: await _currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = "People API gave a ${response.statusCode} "
            "response. Check logs for details.";
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final String namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = "I see you know $namedContact!";
      } else {
        _contactText = "No contacts to display.";
      }
    });
  }

  String _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'];
    final Map<String, dynamic> contact = connections?.firstWhere(
      (dynamic contact) => contact['names'] != null,
      orElse: () => null,
    );
    if (contact != null) {
      final Map<String, dynamic> name = contact['names'].firstWhere(
        (dynamic name) => name['displayName'] != null,
        orElse: () => null,
      );
      if (name != null) {
        return name['displayName'];
      }
    }
    return null;
  }

  // google sign in
  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    if (_currentUser != null) {
      return Container(
        child: Painter(
          paintController: _controller,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  Future uploadFile(DriveApi api, io.File file, String filename) {
    var media = Media(file.openRead(), file.lengthSync());
    return api.files
        .create(File.fromJson({"name": filename}), uploadMedia: media)
        .then((File f) {
      print('Uploaded $file. Id: ${f.id}');
    }).whenComplete(() {
      // reload content after upload the file
      //_handleGetFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // redoボタン
          FloatingActionButton(
            heroTag: "save",
            onPressed: () async {
              var client =
                  GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
              var api = DriveApi(client);
              if (_controller.canRedo) {
                io.File output = await _controller.redo();
                uploadFile(api, output, "String filename");
              }
            },
            child: Text("save"),
          ),

          SizedBox(
            height: 20.0,
          ),

          // クリアボタン
          FloatingActionButton(
            heroTag: "clear",
            onPressed: () => _controller.clear(),
            child: Text("clear"),
          ),
        ],
      ),
    );
  }
}

// Google auth client
class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(_headers));
}
