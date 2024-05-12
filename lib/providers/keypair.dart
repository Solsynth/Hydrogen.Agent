import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solian/models/keypair.dart';
import 'package:solian/models/packet.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class KeypairProvider extends ChangeNotifier {
  static const storage = FlutterSecureStorage();
  static const encryptIV = 'WT7s~><Ae?YrJd)D';

  WebSocketChannel? channel;

  String? activeKeyId;
  Map<String, Keypair> keys = {};
  List<String> requestingKeys = List.empty(growable: true);

  KeypairProvider() {
    loadKeys();
  }

  void loadKeys() async {
    final result = await storage.read(key: 'keypair');
    if (result != null) {
      jsonDecode(result).values.forEach((x) {
        keys[x['id']] = Keypair.fromJson(x);
      });
      activeKeyId = await storage.read(key: 'keypairActive');
    }
    notifyListeners();
  }

  void saveKeys() async {
    await storage.write(key: 'keypair', value: jsonEncode(keys));
    if (activeKeyId != null) {
      await storage.write(key: 'keypairActive', value: activeKeyId);
    }
  }

  void receiveKeypair(Keypair kp) {
    keys[kp.id] = kp;
    requestingKeys.remove(kp.id);
    saveKeys();
    notifyListeners();
  }

  Keypair? provideKeypair(String id) {
    print(id);
    print(keys[id]);
    return keys[id];
  }

  void importKeys(String code) {
    final result = jsonDecode(utf8.fuse(base64).decode(code)).map((x) => Keypair.fromJson(x)).toList();
    for (final item in result) {
      if (item is Keypair) {
        keys[item.id] = item;
      }
    }
    saveKeys();
    notifyListeners();
  }

  void setActiveKey(String id) {
    if (keys[id] == null) return;
    activeKeyId = id;
    saveKeys();
    notifyListeners();
  }

  void clearKeys() {
    keys = {};
    storage.delete(key: 'keypairActive');
    saveKeys();
  }

  bool requestKey(String id, String algorithm, int uid) {
    if (channel == null) return false;
    if (requestingKeys.contains(id)) return false;

    channel!.sink.add(jsonEncode(
      NetworkPackage(method: 'kex.request', payload: {
        'request_id': const Uuid().v4(),
        'keypair_id': id,
        'algorithm': algorithm,
        'owner_id': uid,
        'deadline': 3,
      }).toJson(),
    ));

    requestingKeys.add(id);
    notifyListeners();
    return true;
  }

  String? encodeViaAESKey(String keypairId, String content) {
    if (keys[keypairId] == null) {
      return null;
    } else if (keys[keypairId]?.algorithm != 'aes') {
      throw Exception('invalid algorithm');
    }

    final kp = keys[keypairId]!;
    final iv = encrypt.IV.fromUtf8(encryptIV);
    final key = encrypt.Key.fromBase64(kp.publicKey);
    final encryptor = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.sic, padding: null));
    return encryptor.encryptBytes(utf8.encode(content), iv: iv).base64;
  }

  String? decodeViaAESKey(String keypairId, String encrypted) {
    if (keys[keypairId] == null) {
      return null;
    } else if (keys[keypairId]?.algorithm != 'aes') {
      throw Exception('invalid algorithm');
    }

    final kp = keys[keypairId]!;
    final iv = encrypt.IV.fromUtf8(encryptIV);
    final key = encrypt.Key.fromBase64(kp.publicKey);
    final encryptor = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.sic, padding: null));
    return utf8.decode(encryptor.decryptBytes(encrypt.Encrypted.fromBase64(encrypted), iv: iv));
  }

  Keypair generateAESKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final key = Uint8List.fromList(values);

    final kp = Keypair(
      id: const Uuid().v4(),
      algorithm: 'aes',
      publicKey: base64.encode(key),
      privateKey: null,
      isOwned: true,
    );

    keys[kp.id] = kp;

    return kp;
  }
}
