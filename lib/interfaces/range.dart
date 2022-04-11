import 'package:satellite_dart/interfaces/vector.dart';

class Range extends Vector {
  Range({required double x, required double y, required double z, this.w = 0})
      : super(
          x: x,
          y: y,
          z: z,
        );

  double w;
}
