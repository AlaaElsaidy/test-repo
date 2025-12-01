import 'package:alzcare/core/models/patient-family-relation-model.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';

class PatientFamilyService {
  final _client = SupabaseConfig.client;

  /// Ensure that there is a row in `family_members` for the given [familyMemberId].
  ///
  /// - In التصميم الحالى إحنا مفترضين إن `family_members.id` = `users.id` للفاميلى.
  /// - بعض الداتا القديمة ممكن يكون فيها مستخدم فى جدول `users` بدون صف مطابق
  ///   فى `family_members`، وده بيكسر الـ FK على patient_family_relations.family_member_id.
  /// - الدالة دى بتحاول تلقى صف فى family_members؛ لو مش موجود،
  ///   بتقرا بيانات المستخدم من جدول users وتُنشئ صف جديد فى family_members بنفس الـ id.
  Future<void> _ensureFamilyMemberRow(String familyMemberId) async {
    // لو الصف موجود خلاص، مفيش حاجة نعملها
    final existingFamily = await _client
        .from('family_members')
        .select('id')
        .eq('id', familyMemberId)
        .maybeSingle();

    if (existingFamily != null) return;

    // حاول تجيب بيانات المستخدم من جدول users
    final user = await _client
        .from('users')
        .select('name, email')
        .eq('id', familyMemberId)
        .maybeSingle();

    if (user == null) {
      // لو مفيش مستخدم أصلاً بالـ id ده، يبقى دى حالة داتا غير متوقعة
      // نرمي Exception واضحة عشان تبان فى SupabaseErrorHandler بدلاً من FK error غامض.
      throw Exception(
          'Family member user not found for id: $familyMemberId. Cannot create relation.');
    }

    await _client.from('family_members').insert({
      'id': familyMemberId,
      'name': user['name'],
      'email': user['email'],
    });
  }

  /// Link patient to family member
  Future<PatientFamilyRelationModel> linkPatientToFamily({
    required String patientId,
    required String familyMemberId,
    String? relationType,
  }) async {
    final now = DateTime.now();

    // تأكد إن فيه صف فى family_members بنفس الـ id المستخدم كـ family_member_id
    await _ensureFamilyMemberRow(familyMemberId);

    // Business rule: كل فاميلى مرتبط بمريض واحد فعّال فقط.
    // قبل ما نعمل ربط جديد، نمسح أى علاقات قديمة لنفس الفاميلى مع مرضى تانيين.
    // نسيب فقط العلاقة للمريض الحالى (لو كانت موجودة).
    await _client
        .from('patient_family_relations')
        .delete()
        .eq('family_member_id', familyMemberId)
        .neq('patient_id', patientId);

    // If relation already exists, just return it
    final alreadyExists = await relationExists(
      patientId: patientId,
      familyMemberId: familyMemberId,
    );

    if (alreadyExists) {
      final existing = await _client
          .from('patient_family_relations')
          .select()
          .eq('patient_id', patientId)
          .eq('family_member_id', familyMemberId)
          .single();

      // Try to back-fill family_members.patient_id
      try {
        await _client
            .from('family_members')
            .update({'patient_id': patientId})
            .eq('id', familyMemberId);
      } catch (_) {
        // Ignore any FK/constraint errors – relation itself already exists
      }

      return PatientFamilyRelationModel.fromJson(existing);
    }

    // Insert new relation
    final response = await _client.from('patient_family_relations').insert({
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      if (relationType != null) 'relation_type': relationType,
      'created_at': now.toIso8601String(),
    }).select().single();

    // After creating relation, try to set family_members.patient_id as well
    try {
      await _client
          .from('family_members')
          .update({'patient_id': patientId})
          .eq('id', familyMemberId);
    } catch (_) {
      // Ignore errors here – core relation is stored in patient_family_relations
    }

    return PatientFamilyRelationModel.fromJson(response);
  }

  /// Get all family members for a patient
  Future<List<Map<String, dynamic>>> getFamilyMembersByPatient(
      String patientId) async {
    final response = await _client
        .from('patient_family_relations')
        .select('''
          *,
          family_members (
            id,
            name,
            email,
            phone,
            image_url
          )
        ''')
        .eq('patient_id', patientId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get all patients for a family member
  Future<List<Map<String, dynamic>>> getPatientsByFamily(
      String familyMemberId) async {
    // Business rule: فى التطبيق كل فاميلى مرتبط بمريض واحد فعّال فقط.
    // أولاً نحاول الاعتماد على العمود family_members.patient_id لأنه
    // الأكثر استقراراً ويعبر عن المريض الحالى لهذا الفاميلى.
    try {
      final familyRow = await _client
          .from('family_members')
          .select('patient_id')
          .eq('id', familyMemberId)
          .maybeSingle();

      final String? primaryPatientId = familyRow?['patient_id'] as String?;

      if (primaryPatientId != null && primaryPatientId.isNotEmpty) {
        final patient = await _client
            .from('patients')
            .select('''
              id,
              user_id,
              name,
              age,
              gender,
              photo_url
            ''')
            .eq('id', primaryPatientId)
            .maybeSingle();

        if (patient != null) {
          // نرجع ليست فيها عنصر واحد بنفس شكل patient_family_relations + join
          return [
            {
              'patient_id': primaryPatientId,
              'family_member_id': familyMemberId,
              'patients': patient,
              'relation_type': null,
            },
          ];
        }
      }
    } catch (_) {
      // لو حصل أى خطأ، هنرجع للمنطق القديم كـ fallback
    }

    // Fallback: استخدام جدول العلاقات مباشرة (قد يرجع أكتر من مريض لو الداتا قديمة)
    final response = await _client
        .from('patient_family_relations')
        .select('''
          *,
          patients (
            id,
            user_id,
            name,
            age,
            gender,
            photo_url
          )
        ''')
        .eq('family_member_id', familyMemberId)
        // الأحدث أولاً، لأن آخر ربط معمول غالباً هو الصحيح للمستخدم
        .order('created_at', ascending: false);

    final list = (response as List).cast<Map<String, dynamic>>();

    if (list.isEmpty) return list;

    // حتى مع الداتا القديمة، نرجع فقط أول مريض (واحد بس للفاميلى)
    return [list.first];
  }

  /// Remove relation between patient and family member
  Future<void> removeRelation({
    required String patientId,
    required String familyMemberId,
  }) async {
    await _client
        .from('patient_family_relations')
        .delete()
        .eq('patient_id', patientId)
        .eq('family_member_id', familyMemberId);
  }

  /// Check if relation exists
  Future<bool> relationExists({
    required String patientId,
    required String familyMemberId,
  }) async {
    final response = await _client
        .from('patient_family_relations')
        .select()
        .eq('patient_id', patientId)
        .eq('family_member_id', familyMemberId)
        .maybeSingle();

    return response != null;
  }
}



