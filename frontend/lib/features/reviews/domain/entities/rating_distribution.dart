import 'package:equatable/equatable.dart';

class RatingDistribution extends Equatable {
  const RatingDistribution({
    this.oneStar = 0,
    this.twoStar = 0,
    this.threeStar = 0,
    this.fourStar = 0,
    this.fiveStar = 0,
  });

  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  int get totalRatings => oneStar + twoStar + threeStar + fourStar + fiveStar;

  double getPercentage(int star) {
    if (totalRatings == 0) return 0.0;
    final count = switch (star) {
      5 => fiveStar,
      4 => fourStar,
      3 => threeStar,
      2 => twoStar,
      1 => oneStar,
      _ => 0,
    };
    return count / totalRatings;
  }

  @override
  List<Object?> get props => [oneStar, twoStar, threeStar, fourStar, fiveStar];
}
