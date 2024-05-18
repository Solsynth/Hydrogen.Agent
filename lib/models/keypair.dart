class Keypair {
  final String id;
  final String algorithm;
  final String publicKey;
  final String? privateKey;

  final bool isOwned;

  Keypair({
    required this.id,
    required this.algorithm,
    required this.publicKey,
    required this.privateKey,
    this.isOwned = false,
  });

  factory Keypair.fromJson(Map<String, dynamic> json) => Keypair(
        id: json['id'],
        algorithm: json['algorithm'],
        publicKey: json['public_key'],
        privateKey: json['private_key'],
        isOwned: json['is_owned'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'algorithm': algorithm,
        'public_key': publicKey,
        'private_key': privateKey,
        'is_owned': isOwned,
      };
}
