import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';
import 'Painter.dart';
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        //_handleGetFiles();
      }
    });
    _googleSignIn.signInSilently();
  }

  // google sign in
  Future<Null> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<String> get getDbPath async {
    final dbDir =
        await getApplicationDocumentsDirectory(); //ファイルが保存されている領域のパスを取得
    return dbDir.path + "/filename.csv";
  }

  // upload file to Google drive
  Future uploadFile(DriveApi api, String filename) async {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        transitionDuration: Duration(seconds: 2),
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          return Center(
            child: CircularProgressIndicator(),
          );
        });
    File fileToUpload = File(); //ドライブ用のファイルのインスタンスを作成
    fileToUpload.mimeType = "application/vnd.google-apps.spreadsheet";
    fileToUpload.name = filename; //ファイルの名前をセット
    fileToUpload.modifiedTime = DateTime.now().toUtc(); //アップロードの日付
    var filePath = await getDbPath; //DBファイルのパスを関数で取得
    var file = io.File(filePath);
    var media = Media(file.openRead(), file.lengthSync());
    final result = await api.files.create(fileToUpload, uploadMedia: media);
    print("Upload result: $result");
    Navigator.pop(context); //ローディング画面を消す
    //デバック用
    print("ファイル保存が完了しました");
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
        drawerEdgeDragWidth: 0,
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
              var client =
                  GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
              var api = DriveApi(client);
              await _controller.save();
              await uploadFile(
                      api,
                      DateTime.now().toIso8601String().substring(0, 19) +
                          ".csv")
                  .whenComplete(() => client.close());
            },
            label: 'Save',
            labelStyle: TextStyle(fontWeight: FontWeight.w500),
          ),
          SpeedDialChild(
            child: Icon(Icons.delete),
            backgroundColor: Colors.deepOrangeAccent,
            onTap: () async {
              _controller.undo();
              var filePath = await getDbPath; //DBファイルのパスを関数で取得
              var file = io.File(filePath);
              file.delete();
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
