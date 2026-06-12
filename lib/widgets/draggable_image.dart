import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

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
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: (details) {
          _previousScale = _scale;
        },
        onScaleUpdate: (details) {
          setState(() {
            _offset += details.focalPointDelta;
            _scale = (_previousScale * details.scale).clamp(0.5, 5.0);
          });
        },
        child: Transform(
          transform: Matrix4.identity()
            ..translateByVector3(v64.Vector3(_offset.dx, _offset.dy, 0.0))
            ..scaleByVector3(v64.Vector3(_scale, _scale, 1.0)),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
