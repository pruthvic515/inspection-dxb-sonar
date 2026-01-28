import 'constants.dart';

class LayoutValues {
  final double horizontal;
  final double vertical;
  final double cardTop;

  LayoutValues({
    required this.horizontal,
    required this.vertical,
    required this.cardTop,
  });

  factory LayoutValues.fromWidth(double width) {
    final isLarge = width > SIZE_600;

    return LayoutValues(
      horizontal: isLarge ? 33 : 23,
      vertical: isLarge ? 20 : 10,
      cardTop: isLarge ? 15 : 10,
    );
  }
}