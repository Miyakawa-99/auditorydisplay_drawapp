import 'package:flutter/material.dart';
import 'Painter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
       * AppBar
       */
      appBar: AppBar(
        title: Text('ペイント'),
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
