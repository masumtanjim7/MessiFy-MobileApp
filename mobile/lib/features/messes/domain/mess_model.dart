class MembershipModel {
  final int id;
  final String role;
  final bool isActive;
  final String joinedAt;

  const MembershipModel({
    required this.id,
    required this.role,
    required this.isActive,
    required this.joinedAt,
  });

  factory MembershipModel.fromJson(Map<dynamic, dynamic> json) {
    return MembershipModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      role: json['role']?.toString() ?? 'member',
      isActive: json['is_active'] as bool? ?? true,
      joinedAt: json['joined_at']?.toString() ?? '',
    );
  }
}

class MessModel {
  final int id;
  final String name;
  final String? address;
  final String inviteCode;
  final MembershipModel? currentMembership;

  const MessModel({
    required this.id,
    required this.name,
    this.address,
    required this.inviteCode,
    this.currentMembership,
  });

  factory MessModel.fromJson(Map<dynamic, dynamic> json) {
    return MessModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      inviteCode: json['invite_code']?.toString() ?? '',
      currentMembership: json['membership'] != null
          ? MembershipModel.fromJson(json['membership'] as Map<dynamic, dynamic>)
          : null,
    );
  }
}