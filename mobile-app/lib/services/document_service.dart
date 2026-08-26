import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../models/clinical_attachment.dart';

class DocumentService {
  DocumentService(this.api);
  final ApiClient api;

  Future<List<ClinicalAttachment>> list(String petId) async {
    final raw = await api.getList('/pets/$petId/attachments');
    return raw.map((e) => ClinicalAttachment.fromJson(e as Map<String, dynamic>)).toList();
  }

  String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

  String inferMimeType(String fileName, Uint8List bytes) =>
      lookupMimeType(fileName, headerBytes: bytes.take(24).toList()) ?? 'application/octet-stream';

  Future<ClinicalAttachment> upload({
    required String petId,
    required String fileName,
    required Uint8List bytes,
    String? medicalRecordId,
  }) async {
    if (bytes.isEmpty) throw ArgumentError('Arquivo vazio');
    if (bytes.length > 50000000) throw ArgumentError('Arquivo excede 50 MB');

    final hash = sha256Hex(bytes);
    final mimeType = inferMimeType(fileName, bytes);

    final intent = await api.post('/pets/$petId/attachments/upload-intent', {
      'fileName': fileName,
      'mimeType': mimeType,
      'sha256': hash,
      'sizeBytes': bytes.length,
    }, authenticated: true);

    final uploadUrl = intent['uploadUrl'] as String;
    final storageKey = intent['storageKey'] as String;
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': mimeType,
        'x-amz-meta-sha256': hash,
      },
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'Falha no envio do arquivo para o armazenamento seguro');
    }

    final registered = await api.post('/pets/$petId/attachments/register', {
      'fileName': fileName,
      'mimeType': mimeType,
      'storageKey': storageKey,
      'sha256': hash,
      'sizeBytes': bytes.length,
      if (medicalRecordId != null) 'medicalRecordId': medicalRecordId,
    }, authenticated: true);

    return ClinicalAttachment.fromJson(registered);
  }

  Future<void> openDownload(String petId, ClinicalAttachment attachment) async {
    final intent = await api.post('/pets/$petId/attachments/${attachment.id}/download-intent', {}, authenticated: true);
    final uri = Uri.parse(intent['downloadUrl'] as String);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ApiException(0, 'Não foi possível abrir o documento');
    }
  }
}
