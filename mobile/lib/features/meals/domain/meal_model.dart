class MealModel {
  final int id;
  final int membershipId;
  final String userName;
  final String date;
  final double breakfast;
  final double lunch;
  final double dinner;
  final double totalMeals;

  const MealModel({
    required this.id,
    required this.membershipId,
    required this.userName,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.totalMeals,
  });

  factory MealModel.fromJson(Map<dynamic, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return MealModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      membershipId: json['membership'] is int
          ? json['membership'] as int
          : int.tryParse(json['membership']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Member',
      date: json['date']?.toString() ?? '',
      breakfast: parseDouble(json['breakfast']),
      lunch: parseDouble(json['lunch']),
      dinner: parseDouble(json['dinner']),
      totalMeals: parseDouble(json['total_meals'] ?? json['total_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}