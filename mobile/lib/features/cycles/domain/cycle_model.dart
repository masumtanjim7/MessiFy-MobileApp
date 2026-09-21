class MonthCycleModel {
  final int id;
  final String name;
  final String status;
  final String startDate;
  final String? endDate;
  final double totalMeals;
  final double totalExpenses;
  final double mealRate;

  const MonthCycleModel({
    required this.id,
    required this.name,
    required this.status,
    required this.startDate,
    this.endDate,
    this.totalMeals = 0.0,
    this.totalExpenses = 0.0,
    this.mealRate = 0.0,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isLocked => status == 'LOCKED';
  bool get isSettled => status == 'SETTLED';

  factory MonthCycleModel.fromJson(Map<dynamic, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return MonthCycleModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'ACTIVE').toUpperCase(),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      totalMeals: parseDouble(json['total_meals']),
      totalExpenses: parseDouble(json['total_expenses']),
      mealRate: parseDouble(json['meal_rate']),
    );
  }
}