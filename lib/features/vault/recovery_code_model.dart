class RecoveryCode {
  final String id;
  final String serviceName;
  final String code; // encrypted
  bool used;

  RecoveryCode({
    required this.id,
    required this.serviceName,
    required this.code,
    this.used = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'code': code,
        'used': used,
      };

  factory RecoveryCode.fromJson(Map<String, dynamic> json) => RecoveryCode(
        id: json['id'],
        serviceName: json['serviceName'],
        code: json['code'],
        used: json['used'] ?? false,
      );
}
