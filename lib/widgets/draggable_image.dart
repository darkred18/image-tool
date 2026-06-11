import 'package:flutter/material.dart';

class DraggableImage extends StatefulWidget {
  final Widget child;

  const DraggableImage({super.key, required this.child});

  @override
  State<DraggableImage> createState() => _DraggableImageState();
}

class _DraggableImageState extends State<DraggableImage> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          // 이동
          _offset += details.focalPointDelta;
          // 줌
          _scale = (_previousScale * details.scale).clamp(0.5, 5.0);
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_offset.dx, _offset.dy)
          ..scale(_scale),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
