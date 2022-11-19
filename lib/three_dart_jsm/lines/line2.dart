import 'index.dart';

class Line2 extends LineSegments2 {
  bool isLine2 = true;

  Line2(geometry, material) : super(geometry, material) {
    type = 'Line2';
  }
}
