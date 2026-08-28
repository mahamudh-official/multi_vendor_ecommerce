import '../../domain/entities/rating_distribution.dart';

class RatingDistributionModel {
  const RatingDistributionModel({
    this.oneStar = 0,
    this.twoStar = 0,
    this.threeStar = 0,
    this.fourStar = 0,
    this.fiveStar = 0,
  });

  factory RatingDistributionModel.fromJson(Map<String, dynamic> json) {
    return RatingDistributionModel(
      oneStar: json['one_star'] as int? ?? 0,
      twoStar: json['two_star'] as int? ?? 0,
      threeStar: json['three_star'] as int? ?? 0,
      fourStar: json['four_star'] as int? ?? 0,
      fiveStar: json['five_star'] as int? ?? 0,
    );
  }

  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  Map<String, dynamic> toJson() {
    return {
      'one_star': oneStar,
      'two_star': twoStar,
      'three_star': threeStar,
      'four_star': fourStar,
      'five_star': fiveStar,
    };
  }

  RatingDistribution toEntity() {
    return RatingDistribution(
      oneStar: oneStar,
      twoStar: twoStar,
      threeStar: threeStar,
      fourStar: fourStar,
      fiveStar: fiveStar,
    );
  }
}
