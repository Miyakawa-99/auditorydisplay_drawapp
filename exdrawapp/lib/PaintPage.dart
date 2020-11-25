import 'package:flutter/material.dart';
import 'Painter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
//import 'dart:async';
import 'dart:convert' show json;
import 'package:http/http.dart';

GoogleSignIn _googleSignIn = new GoogleSignIn(
  scopes: <String>[
    DriveApi.DriveFileScope,
    DriveApi.DriveAppdataScope,
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

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        print("logined");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
       * AppBar
       */
      appBar: AppBar(
        title: Text('StereoDisplayEx'),
        centerTitle: true,
      ),

      /*
       * body
       */
      body: Container(
        child: Painter(
          paintController: _controller,
        ),
      ),

      /*
       * floatingActionButton
       */
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // undoボタン
          FloatingActionButton(
            heroTag: "undo",
            onPressed: () {
              if (_controller.canUndo) _controller.undo();
            },
            child: Text("undo"),
          ),

          SizedBox(
            height: 20.0,
          ),

          // redoボタン
          FloatingActionButton(
            heroTag: "redo",
            onPressed: () {
              if (_controller.canRedo) _controller.redo();
            },
            child: Text("redo"),
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
