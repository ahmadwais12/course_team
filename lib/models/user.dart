enum UserRole {
  ceo,
  superAdmin,
  admin,
  teacher,
  student,
  parent,
  staff,
  academicSupport,
  accountant,
  librarian,
  receptionist,
  hrManager,
  inventoryManager,
  itSupport,
  maintenance,
  eventManager,
  complaintManager;

  String get dbValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.academicSupport:
        return 'academic_support';
      case UserRole.hrManager:
        return 'hr_manager';
      case UserRole.inventoryManager:
        return 'inventory_manager';
      case UserRole.itSupport:
        return 'it_support';
      case UserRole.eventManager:
        return 'event_manager';
      case UserRole.complaintManager:
        return 'complaint_manager';
      default:
        return name;
    }
  }

  static UserRole fromDb(String value) {
    return UserRole.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => UserRole.student,
    );
  }
}

class User {
  final String id;
  final String? tenantId;
  final String email;
  final String fullName;
  final String? fullNameAr;
  final String? firstNameAr;
  final String? lastNameAr;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final String? tazkiraNumber;
  final String? passportId;
  final String? bloodGroup;
  final String? nationality;
  final String? religion;
  final String? fatherName;
  final String? fatherNameAr;
  final String? motherName;
  final String? motherNameAr;
  final String? maritalStatus;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    this.tenantId,
    required this.email,
    required this.fullName,
    this.fullNameAr,
    this.firstNameAr,
    this.lastNameAr,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.address,
    this.tazkiraNumber,
    this.passportId,
    this.bloodGroup,
    this.nationality,
    this.religion,
    this.fatherName,
    this.fatherNameAr,
    this.motherName,
    this.motherNameAr,
    this.maritalStatus,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'email': email,
        'full_name': fullName,
        'full_name_ar': fullNameAr,
        'first_name_ar': firstNameAr,
        'last_name_ar': lastNameAr,
        'role': role.dbValue,
        'avatar_url': avatarUrl,
        'phone': phone,
        'address': address,
        'tazkira_number': tazkiraNumber,
        'passport_id': passportId,
        'blood_group': bloodGroup,
        'nationality': nationality,
        'religion': religion,
        'father_name': fatherName,
        'father_name_ar': fatherNameAr,
        'mother_name': motherName,
        'mother_name_ar': motherNameAr,
        'marital_status': maritalStatus,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'emergency_contact_relation': emergencyContactRelation,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String?,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        fullNameAr: json['full_name_ar'] as String?,
        firstNameAr: json['first_name_ar'] as String?,
        lastNameAr: json['last_name_ar'] as String?,
        role: UserRole.fromDb(json['role'] as String),
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        tazkiraNumber: json['tazkira_number'] as String?,
        passportId: json['passport_id'] as String?,
        bloodGroup: json['blood_group'] as String?,
        nationality: json['nationality'] as String?,
        religion: json['religion'] as String?,
        fatherName: json['father_name'] as String?,
        fatherNameAr: json['father_name_ar'] as String?,
        motherName: json['mother_name'] as String?,
        motherNameAr: json['mother_name_ar'] as String?,
        maritalStatus: json['marital_status'] as String?,
        emergencyContactName: json['emergency_contact_name'] as String?,
        emergencyContactPhone: json['emergency_contact_phone'] as String?,
        emergencyContactRelation: json['emergency_contact_relation'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  User copyWith({
    String? id,
    String? tenantId,
    String? email,
    String? fullName,
    String? fullNameAr,
    String? firstNameAr,
    String? lastNameAr,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    String? address,
    String? tazkiraNumber,
    String? passportId,
    String? bloodGroup,
    String? nationality,
    String? religion,
    String? fatherName,
    String? fatherNameAr,
    String? motherName,
    String? motherNameAr,
    String? maritalStatus,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      User(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        fullNameAr: fullNameAr ?? this.fullNameAr,
        firstNameAr: firstNameAr ?? this.firstNameAr,
        lastNameAr: lastNameAr ?? this.lastNameAr,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        tazkiraNumber: tazkiraNumber ?? this.tazkiraNumber,
        passportId: passportId ?? this.passportId,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        nationality: nationality ?? this.nationality,
        religion: religion ?? this.religion,
        fatherName: fatherName ?? this.fatherName,
        fatherNameAr: fatherNameAr ?? this.fatherNameAr,
        motherName: motherName ?? this.motherName,
        motherNameAr: motherNameAr ?? this.motherNameAr,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        emergencyContactRelation:
            emergencyContactRelation ?? this.emergencyContactRelation,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
