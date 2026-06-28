import 'package:flutter/material.dart';

class WhiteboardScreen extends StatefulWidget {
  final String conversationId;
  final String conversationName;

  const WhiteboardScreen({
    Key? key,
    required this.conversationId,
    required this.conversationName,
  }) : super(key: key);

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  late List<Offset> _points;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  final List<List<Offset>> _drawings = [];

  @override
  void initState() {
    super.initState();
    _points = [];
  }

  void _clearCanvas() {
    setState(() {
      _drawings.clear();
      _points.clear();
    });
  }

  void _undo() {
    if (_drawings.isNotEmpty) {
      setState(() {
        _drawings.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tableau blanc - ${widget.conversationName}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Color(0xFF5A67D8)),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanDown: (details) {
                setState(() {
                  _points = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _drawings.add(List.from(_points));
                  _points = [];
                });
              },
              child: CustomPaint(
                painter: WhiteboardPainter(
                  drawings: _drawings,
                  currentLine: _points,
                  color: _selectedColor,
                  strokeWidth: _strokeWidth,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          // Color and size selector
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Color palette
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    const Color(0xFF5A67D8),
                  ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: _selectedColor == color
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Stroke width slider
                Row(
                  children: [
                    const Text('Épaisseur:'),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1,
                        max: 10,
                        onChanged: (value) =>
                            setState(() => _strokeWidth = value),
                      ),
                    ),
                    Text('${_strokeWidth.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<List<Offset>> drawings;
  final List<Offset> currentLine;
  final Color color;
  final double strokeWidth;

  WhiteboardPainter({
    required this.drawings,
    required this.currentLine,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw previous drawings
    for (final drawing in drawings) {
      for (int i = 0; i < drawing.length - 1; i++) {
        canvas.drawLine(drawing[i], drawing[i + 1], paint);
      }
    }

    // Draw current line
    for (int i = 0; i < currentLine.length - 1; i++) {
      canvas.drawLine(currentLine[i], currentLine[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) {
    return oldDelegate.drawings != drawings ||
        oldDelegate.currentLine != currentLine;
  }
}
