import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/rendering.dart';
import 'package:googleapis/drive/v3.dart';

// import 'package:csv/csv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:simple_permissions/simple_permissions.dart';

/*
 * ペイントデータ
 */
class _PaintData {
  _PaintData({
    this.path,
  }) : super();

  Path path; //  パス
}

/*
 * ペイントの履歴を管理するクラス
 */
class PaintHistory {
  var xlist = List();
  var ylist = List();
  // ペイントの履歴リスト
  List<MapEntry<_PaintData, Paint>> _paintList =
      List<MapEntry<_PaintData, Paint>>();
  // ペイントundoリスト
  List<MapEntry<_PaintData, Paint>> _undoneList =
      List<MapEntry<_PaintData, Paint>>();
  // 背景ペイント
  Paint _backgroundPaint = Paint();
  // ドラッグ中フラグ
  bool _inDrag = false;
  // カレントペイント
  Paint currentPaint;

  /*
   * undo可能か
   */
  bool canUndo() => _paintList.length > 0;

  /*
   * redo可能か
   */
  bool canRedo() => _paintList.length > 0;

  /*
   * undo
   */
  void undo() {
    if (!_inDrag && canUndo()) {
      _undoneList.add(_paintList.removeLast());
    }
  }

  /*
   * redo
   */
  void redo() {
    if (!_inDrag && canRedo()) {
      print("save");
      print(xlist);
      listtoCSV(xlist);
      uploadFile(api, listtoCSV(xlist), "String filename");
      //listtoCSV(xlist);
    }
  }

  /*
   * クリア
   */
  void clear() {
    if (!_inDrag) {
      _paintList.clear();
      _undoneList.clear();
      xlist.clear();
      ylist.clear();
    }
  }

  // upload file to Google drive
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

  listtoCSV(associateList) async {
    //create an element rows of type list of list. All the above data set are stored in associate list
    //Let associate be a model class with attributes name,gender and age and associateList be a list of associate model class.

    List<List<dynamic>> rows = List<List<dynamic>>();
    for (int i = 0; i < associateList.length; i++) {
      //row refer to each column of a row in csv file and rows refer to each row in a file
      List<dynamic> row = List();
      row.add(associateList[i].name);
      row.add(associateList[i].gender);
      row.add(associateList[i].age);
      rows.add(row);
    }
  }

  /*await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    bool checkPermission = await SimplePermissions.checkPermission(
        Permission.WriteExternalStorage);
    if (checkPermission) {
      //store file in documents folder
      String dir =
          (await getExternalStorageDirectory()).absolute.path + "/documents";
      // file = "$dir";
      // print(LOGTAG + " FILE " + file);
      // File f = new File(file + "filename.csv");

      // convert rows to String and write as csv file
      String csv = const ListToCsvConverter().convert(rows);
      //f.writeAsString(csv);
    }
  }*/

  /*
   * 背景色セッター
   */
  set backgroundColor(color) => _backgroundPaint.color = color;

  /*
   * 線ペイント開始
   */
  void addPaint(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      Path path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      _PaintData data = _PaintData(path: path);
      _paintList.add(MapEntry<_PaintData, Paint>(data, currentPaint));
      print("start");
    }
  }

  /*
   * 線ペイント更新
   */
  void updatePaint(Offset nextPoint) {
    if (_inDrag) {
      _PaintData data = _paintList.last.key;
      Path path = data.path;
      path.lineTo(nextPoint.dx, nextPoint.dy);
      //print(nextPoint.dx);
      xlist.add(nextPoint.dx);
      ylist.add(nextPoint.dy);
    }
  }

  /*
   * 線ペイント終了
   */
  void endPaint() {
    _inDrag = false;
  }

  /*
   * 描写
   */
  void draw(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        0.0,
        0.0,
        size.width,
        size.height,
      ),
      _backgroundPaint,
    );

    /*
     * 線描写
     */
    for (MapEntry<_PaintData, Paint> data in _paintList) {
      if (data.key.path != null) {
        canvas.drawPath(data.key.path, data.value);
      }
    }
  }
}
