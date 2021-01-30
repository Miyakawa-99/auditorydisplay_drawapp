import 'dart:io' as io;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:googleapis/drive/v3.dart' as v3;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'dart:async';

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
  io.File outputFile;
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
  redo() async {
    if (!_inDrag && canRedo()) {
      print("save");
      await getCsv(); //uploadFile(api, getCsv(), "String filename");
      return outputFile;
    }
    return null;
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
  Future uploadFile(v3.DriveApi api, io.File file, String filename) {
    var media = v3.Media(file.openRead(), file.lengthSync());
    return api.files
        .create(v3.File.fromJson({"name": filename}), uploadMedia: media)
        .then((v3.File f) {
      print('Uploaded $file. Id: ${f.id}');
    }).whenComplete(() {
      // reload content after upload the file
      //_handleGetFiles();
    });
  }

/////////
  getCsv() async {
    //create an element rows of type list of list. All the above data set are stored in associate list
//Let associate be a model class with attributes name,gender and age and associateList be a list of associate model class.
    List<List<dynamic>> rows = List<List<dynamic>>();
    for (int i = 0; i < xlist.length; i++) {
//row refer to each column of a row in csv file and rows refer to each row in a file
      List<dynamic> row = List();
      row.add(xlist[i]);
      row.add(ylist[i]);
      rows.add(row);
    }
    io.Directory directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    outputFile = io.File("${directory.path}/filename.csv");
    // convert rows to String and write as csv file
    String csv = const ListToCsvConverter().convert(rows);
    outputFile.writeAsString(csv);
    //}
  }

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
