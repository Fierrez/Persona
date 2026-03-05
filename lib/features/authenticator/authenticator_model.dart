class AuthenticatorEntry {
  final String id;
  final String serviceName;
  final String accountName;
  final String secretKey; // encrypted

  AuthenticatorEntry({
    required this.id,
    required this.serviceName,
    required this.accountName,
    required this.secretKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'accountName': accountName,
        'secretKey': secretKey,
      };

  factory AuthenticatorEntry.fromJson(Map<String, dynamic> json) => AuthenticatorEntry(
        id: json['id'],
        serviceName: json['serviceName'],
        accountName: json['accountName'],
        secretKey: json['secretKey'],
      );
}
