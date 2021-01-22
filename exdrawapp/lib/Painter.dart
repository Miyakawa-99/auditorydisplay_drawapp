import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'PaintHistory.dart';
import 'dart:io';

/*
 * ペイント
 */
class Painter extends StatefulWidget {
  // ペイントコントローラ
  final PaintController paintController;

  Painter({@required this.paintController})
      : super(key: ValueKey<PaintController>(paintController)) {
    assert(this.paintController != null);
  }

  @override
  _PainterState createState() => _PainterState();
}

/*
 * ペイント ステート
 */
class _PainterState extends State<Painter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // イベント監視
      child: GestureDetector(
        // カスタムペイント
        child: CustomPaint(
          willChange: true,
          // ペイント部分
          painter: _CustomPainter(
            widget.paintController._paintHistory,
            repaint: widget.paintController,
          ),
        ),

        // イベントリスナー
        onPanStart: _onPaintStart,
        onPanUpdate: _onPaintUpdate,
        onPanEnd: _onPaintEnd,
      ),
      width: double.infinity,
      height: double.infinity,
    );
  }

  /*
   * 線ペイントの開始
   */
  void _onPaintStart(DragStartDetails start) {
    widget.paintController._paintHistory
        .addPaint(_getGlobalToLocalPosition(start.globalPosition));
    widget.paintController._notifyListeners();
  }

  /*
   * 線ペイント更新
   */
  void _onPaintUpdate(DragUpdateDetails update) {
    widget.paintController._paintHistory
        .updatePaint(_getGlobalToLocalPosition(update.globalPosition));
    widget.paintController._notifyListeners();
  }

  /*
   * 線ペイントの終了
   */
  void _onPaintEnd(DragEndDetails end) {
    widget.paintController._paintHistory.endPaint();
    widget.paintController._notifyListeners();
  }

  /*
   * ローカルのオフセットへ変換
   */
  Offset _getGlobalToLocalPosition(Offset global) {
    return (context.findRenderObject() as RenderBox).globalToLocal(global);
  }
}

/*
 * カスタムペイント
 */
class _CustomPainter extends CustomPainter {
  final PaintHistory _paintHistory;

  _CustomPainter(this._paintHistory, {Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _paintHistory.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_CustomPainter oldDelegate) => true;
}

/*
 * ペイントコントローラ
 */
class PaintController extends ChangeNotifier {
  // ペイント履歴
  PaintHistory _paintHistory = PaintHistory();
  // 線の色
  Color _drawColor = Color.fromARGB(255, 0, 0, 0);
  // 線幅
  double _thickness = 5.0;
  // 背景色
  Color _backgroundColor = Color.fromARGB(255, 255, 255, 255);

  /*
   * コンストラクタ
   */
  PaintController() : super() {
    // ペイント設定
    Paint paint = Paint();
    paint.color = _drawColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = _thickness;
    _paintHistory.currentPaint = paint;
    _paintHistory.backgroundColor = _backgroundColor;
  }

  /*
   * undo実行
   */
  void undo() {
    _paintHistory.undo();
    notifyListeners();
  }

  /*
   * redo実行
   */
  redo() async {
    File output = await _paintHistory.redo();
    notifyListeners();
    return output;
  }

  /*
   * undo可能か
   */
  bool get canUndo => _paintHistory.canUndo();

  /*
   * redo可能か
   */
  bool get canRedo => _paintHistory.canRedo();

  /*
   * リスナー実行
   */
  void _notifyListeners() {
    notifyListeners();
  }

  /*
   * クリア
   */
  void clear() {
    _paintHistory.clear();
    notifyListeners();
  }
}
