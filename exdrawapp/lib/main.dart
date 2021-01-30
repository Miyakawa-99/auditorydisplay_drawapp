import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';
import 'Painter.dart';
import 'package:http/io_client.dart';

GoogleSignIn _googleSignIn = new GoogleSignIn(
  scopes: <String>[
    DriveApi.DriveFileScope,
    DriveApi.DriveAppdataScope,
  ],
);

void main() {
  runApp(
    MaterialApp(
      home: MainScreen(),
    ),
  );
}

class MainScreen extends StatefulWidget {
  @override
  State createState() => new MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  GoogleSignInAccount _currentUser;
  // コントローラ
  PaintController _controller = PaintController();
  String _contactText;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetFiles();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<Null> _handleGetFiles() async {
    final Response response = await get(
      'https://www.googleapis.com/drive/v3/files',
      headers: await _currentUser.authHeaders,
    );
    if (response.statusCode != 200) {
      print('Drive API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data = json.decode(response.body);
    var tmpItemList = <Widget>[];
    var size = MediaQuery.of(context).size;
    var margin = 10;
    var photoWidth = size.width - margin;
    var photoHeight = 200.0;
    for (var i = 0; i < data['files'].length; i++) {
      print(data['files'][i]['name']);
      print(data['files'][i]['id']);
      tmpItemList.add(Column(children: <Widget>[
        Text(data['files'][i]['name'],
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            )),
        GestureDetector(
            child: Card(
              child: Center(
                  child: FadeInImage(
                placeholder: AssetImage('images/placeholder.png'),
                image: NetworkImage(
                    "https://www.googleapis.com/drive/v3/files/" +
                        data['files'][i]['id'] +
                        "?alt=media",
                    headers: await _googleSignIn.currentUser.authHeaders),
                fadeOutDuration: new Duration(milliseconds: 300),
                fadeOutCurve: Curves.decelerate,
                height: photoHeight,
                width: photoWidth,
                fit: BoxFit.fitWidth,
              )),
              elevation: 3.0,
            ),
            onTap: () async {
              var headers = await _googleSignIn.currentUser.authHeaders;
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //       builder: (context) =>
              //           DetailScreen(data['files'][i], headers)),
              // );
            }),
      ]));
    }

    // replace listview content
    setState(() {
      if (tmpItemList.length > 0) {
        itemList = tmpItemList;
//        listView = ListView(children: itemList);
      }
    });
  }

  // google sign in
  Future<Null> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  // Select or take a pic
  // Future getImage(ImageSource src) async {
  //   final picker = ImagePicker();
  //   File _image;
  //   var image = picker.getImage(source: src);
  //   _image = File(image.path);
  //   var client = GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
  //   var api = DriveApi(client);

  //   uploadFile(api, _image,
  //           DateTime.now().toIso8601String().substring(0, 19) + ".jpg")
  //       .whenComplete(() => client.close());
  // }

  // upload file to Google drive
  Future uploadFile(DriveApi api, io.File file, String filename) {
    var media = Media(file.openRead(), file.lengthSync());
    return api.files
        .create(File.fromJson({"name": filename}), uploadMedia: media)
        .then((File f) {
      print('Uploaded $file. Id: ${f.id}');
    }).whenComplete(() {
      // reload content after upload the file
      _handleGetFiles();
    });
  }

  // items
  var itemList = <Widget>[
    Center(
        child: Padding(
            padding: EdgeInsets.only(top: 300.0),
            child: Text("No Report to display",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                )))),
  ];
  var listView;

  // main content
  Widget _buildBody() {
    if (_currentUser != null) {
      listView = ListView(children: itemList);
      return Container(
        child: Painter(
          paintController: _controller,
        ),
      );
    } else {
      return Center(
          child: SizedBox(
        height: 70.0,
        width: 382.0,
        child: IconButton(
          icon: Image.asset("images/btn_google_signin_dark_normal.png"),
          onPressed: _handleSignIn,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('ExApp'),
        ),
        drawer: _drawer(),
        body: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ),
        floatingActionButton: _fabButton());
  }

  Widget _drawer() {
    if (_currentUser != null) {
      // login user drawer
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: ListTile(
                  leading: GoogleUserCircleAvatar(
                    identity: _currentUser,
                  ),
                  title: Text(_currentUser.displayName),
                  subtitle: Text(_currentUser.email),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                _googleSignIn.disconnect();
              },
            ),
          ],
        ),
      );
    }
    // no login drawer
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: Text("Guest user"),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // FAB icon
  Widget _fabButton() {
    if (_currentUser != null) {
      return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        curve: Curves.bounceIn,
        children: [
          // Select file
          SpeedDialChild(
            child: Icon(Icons.save_alt_rounded),
            backgroundColor: Colors.green,
            onTap: () async {
              await _controller.save();
            },
            label: 'Save',
            labelStyle: TextStyle(fontWeight: FontWeight.w500),
          ),
          SpeedDialChild(
            child: Icon(Icons.delete),
            backgroundColor: Colors.deepOrangeAccent,
            onTap: () {
              _controller.undo();
            },
            label: 'Delete',
            labelStyle: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
    return Center();
  }
}

// Google auth client
class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(_headers));
}

// Photo viewer
// class DetailScreen extends StatelessWidget {
//   var _data;
//   Map<String, String> _headers;
//   DetailScreen(this._data, this._headers);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text(_data['name']),
//         ),
//         body: ZoomableImage(
//             NetworkImage(
//                 "https://www.googleapis.com/drive/v3/files/" +
//                     _data['id'] +
//                     "?alt=media",
//                 headers: _headers),
//             placeholder: Center(child: CircularProgressIndicator()),
//             backgroundColor: Colors.white));
//   }
// }
