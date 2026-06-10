abstract class MessageEncryptionRepository {
  Map<String, dynamic> encryptPayload({
    required String roomId,
    required List<String> participants,
    required Map<String, dynamic> payload,
  });

  Map<String, dynamic>? decryptPayload({
    required String roomId,
    required List<String> participants,
    required Map<String, dynamic>? encryptedPayload,
  });
}
