class StaffPermissions {
  final bool canViewCustomerPhone;
  final bool canCancelAppointments;
  final bool canAddManualBreaks;
  final bool canEditPrices;

  StaffPermissions({
    this.canViewCustomerPhone = false,
    this.canCancelAppointments = true,
    this.canAddManualBreaks = true,
    this.canEditPrices = false,
  });

  factory StaffPermissions.fromMap(Map<String, dynamic> map) {
    return StaffPermissions(
      canViewCustomerPhone: map['canViewCustomerPhone'] ?? false,
      canCancelAppointments: map['canCancelAppointments'] ?? true,
      canAddManualBreaks: map['canAddManualBreaks'] ?? true,
      canEditPrices: map['canEditPrices'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canViewCustomerPhone': canViewCustomerPhone,
      'canCancelAppointments': canCancelAppointments,
      'canAddManualBreaks': canAddManualBreaks,
      'canEditPrices': canEditPrices,
    };
  }
}

class StaffModel {
  final int id;
  final String name;
  final String title;
  final String phone;
  final String avatarUrl;
  final List<int> allowedServices;
  final StaffPermissions permissions;

  StaffModel({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    required this.avatarUrl,
    required this.allowedServices,
    required this.permissions,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      allowedServices: List<int>.from(map['allowedServices'] ?? []),
      permissions: StaffPermissions.fromMap(map['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'allowedServices': allowedServices,
      'permissions': permissions.toMap(),
    };
  }
}
