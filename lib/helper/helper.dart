import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class GridPainter extends CustomPainter {
  GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int i = 0; i <= 3; i++) {
      if (i == 0 || i == 3) {
        paint.strokeWidth = 3.0;
      } else {
        paint.strokeWidth = 1.0;
      }
      double dy = (size.height / 3) * i;
      canvas.drawLine(new Offset(0.0, dy), new Offset(size.width, dy), paint);
    }
    for (int i = 0; i <= 3; i++) {
      if (i == 0 || i == 3) {
        paint.strokeWidth = 3.0;
      } else {
        paint.strokeWidth = 1.0;
      }
      double dx = (size.width / 3) * i;
      canvas.drawLine(new Offset(dx, 0.0), new Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ImagePositionDelegate extends SingleChildLayoutDelegate {
  final double imageWidth;
  final double imageHeight;
  final Offset topLeft;

  const ImagePositionDelegate(this.imageWidth, this.imageHeight, this.topLeft);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return topLeft;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      maxWidth: imageWidth,
      maxHeight: imageHeight,
      minHeight: imageHeight,
      minWidth: imageWidth,
    );
  }

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    return true;
  }
}
