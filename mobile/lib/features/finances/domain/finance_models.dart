class MonthCycleModel {
  final int id;
  final String name;
  final String status;
  final String startDate;
  final String? endDate;

  const MonthCycleModel({
    required this.id,
    required this.name,
    required this.status,
    required this.startDate,
    this.endDate,
  });

  factory MonthCycleModel.fromJson(Map<dynamic, dynamic> json) {
    return MonthCycleModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
    );
  }
}

class MessMembershipModel {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String role;
  final bool isActive;

  const MessMembershipModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.role,
    required this.isActive,
  });

  factory MessMembershipModel.fromJson(Map<dynamic, dynamic> json) {
    return MessMembershipModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['user'] is int
          ? json['user'] as int
          : int.tryParse(json['user']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Member',
      userEmail: json['user_email']?.toString() ?? '',
      userPhone: json['user_phone']?.toString() ?? '',
      role: (json['role']?.toString() ?? 'MEMBER').toUpperCase(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class DepositModel {
  final int id;
  final String userName;
  final double amount;
  final String date;
  final String? notes;

  const DepositModel({
    required this.id,
    required this.userName,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory DepositModel.fromJson(Map<dynamic, dynamic> json) {
    return DepositModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userName: json['user_name']?.toString() ??
          json['member_name']?.toString() ??
          json['membership_name']?.toString() ??
          'Member',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}

class ExpenseModel {
  final int id;
  final String description;
  final double amount;
  final String date;
  final String? category;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
  });

  factory ExpenseModel.fromJson(Map<dynamic, dynamic> json) {
    return ExpenseModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      description: json['description']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Bazaar',
    );
  }
}

class MemberLedgerRow {
  final String memberName;
  final double totalMeals;
  final double totalDeposits;
  final double mealCost;
  final double balance;

  const MemberLedgerRow({
    required this.memberName,
    required this.totalMeals,
    required this.totalDeposits,
    required this.mealCost,
    required this.balance,
  });

  factory MemberLedgerRow.fromJson(Map<dynamic, dynamic> json) {
    return MemberLedgerRow(
      memberName: json['member_name']?.toString() ?? 'Member',
      totalMeals: double.tryParse(json['total_meals']?.toString() ?? '0') ?? 0.0,
      totalDeposits: double.tryParse(json['total_deposits']?.toString() ?? '0') ?? 0.0,
      mealCost: double.tryParse(json['meal_cost']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BalanceSheetModel {
  final double totalMeals;
  final double totalExpenses;
  final double mealRate;
  final List<MemberLedgerRow> memberRows;

  const BalanceSheetModel({
    required this.totalMeals,
    required this.totalExpenses,
    required this.mealRate,
    required this.memberRows,
  });

  factory BalanceSheetModel.fromJson(Map<dynamic, dynamic> json) {
    final rawList = json['members'] ?? json['breakdown'] ?? [];
    final List listData = rawList is List ? rawList : [];

    return BalanceSheetModel(
      totalMeals: double.tryParse(json['total_meals']?.toString() ?? '0') ?? 0.0,
      totalExpenses: double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0.0,
      mealRate: double.tryParse(json['meal_rate']?.toString() ?? '0') ?? 0.0,
      memberRows: listData
          .map((row) => MemberLedgerRow.fromJson(Map<dynamic, dynamic>.from(row)))
          .toList(),
    );
  }
}