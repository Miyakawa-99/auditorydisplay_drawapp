import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
