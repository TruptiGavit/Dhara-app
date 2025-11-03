
import 'package:flutter/widgets.dart';

class ClipCircleBottom extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // var diameter = min(size.width, size.height);

    debugPrint("size: $size");
    var path = Path();
    path.lineTo(0.0, size.height - (size.height * 30) / 100);
    path.lineTo(size.width, size.height - (size.height * 30) / 100);
    path.lineTo(size.width, 0.0);

    // var firstControlPoint = Offset(size.width / 4, size.height);
    // var firstPoint = Offset(size.width / 2, size.height);
    // path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
    //     firstPoint.dx, firstPoint.dy);

    // var secondControlPoint = Offset(size.width - (size.width / 4), size.height);
    // var secondPoint = Offset(size.width, size.height - 30);
    // path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
    //     secondPoint.dx, secondPoint.dy);

    // path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
