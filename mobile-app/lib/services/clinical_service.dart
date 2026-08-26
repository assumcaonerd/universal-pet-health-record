import '../core/api_client.dart';
import '../models/clinical_models.dart';

class ClinicalService {
  ClinicalService(this.api);
  final ApiClient api;

  Future<List<Prescription>> prescriptions(String petId) async {
    final raw = await api.getList('/pets/$petId/prescriptions');
    return raw.map((e) => Prescription.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Allergy>> allergies(String petId) async {
    final raw = await api.getList('/pets/$petId/allergies');
    return raw.map((e) => Allergy.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MedicalRecord>> medicalRecords(String petId) async {
    final raw = await api.getList('/pets/$petId/medical-records');
    return raw.map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Allergy> addAllergy(String petId, {required String allergen, String? reaction, required String severity}) async {
    final raw = await api.post('/pets/$petId/allergies', {
      'allergen': allergen,
      if (reaction != null && reaction.trim().isNotEmpty) 'reaction': reaction.trim(),
      'severity': severity,
    }, authenticated: true);
    return Allergy.fromJson(raw);
  }

  Future<void> deactivateAllergy(String petId, String allergyId) async {
    await api.patch('/pets/$petId/allergies/$allergyId/deactivate', const {});
  }
}
