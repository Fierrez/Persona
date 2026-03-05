class VaultEntry {
  final String id;
  final String serviceName;
  final String username;
  final String password; // encrypted
  final String notes;
  final String category; // Work, Social, Finance, etc.
  final DateTime updatedAt;

  VaultEntry({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.password,
    this.notes = '',
    this.category = 'General',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'password': password,
        'notes': notes,
        'category': category,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: json['id'],
        serviceName: json['serviceName'],
        username: json['username'],
        password: json['password'],
        notes: json['notes'] ?? '',
        category: json['category'] ?? 'General',
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );
}
