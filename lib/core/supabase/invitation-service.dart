import 'dart:math';
import 'package:alzcare/core/models/invitation-model.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';

class InvitationService {
  final _client = SupabaseConfig.client;

  /// Generate unique invitation code
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new invitation (Patient to Family)
  Future<InvitationModel> createInvitation({
    required String patientId,
    String? familyMemberEmail,
    String? familyMemberPhone,
  }) async {
    if (familyMemberEmail == null && familyMemberPhone == null) {
      throw Exception('Either email or phone must be provided');
    }

    String invitationCode = '';
    bool isUnique = false;
    
    // Ensure unique code
    while (!isUnique) {
      invitationCode = _generateInvitationCode();
      final existing = await _client
          .from('invitations')
          .select()
          .eq('invitation_code', invitationCode)
          .maybeSingle();
      isUnique = existing == null;
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final response = await _client.from('invitations').insert({
      'patient_id': patientId,
      if (familyMemberEmail != null) 'family_member_email': familyMemberEmail,
      if (familyMemberPhone != null) 'family_member_phone': familyMemberPhone,
      'invitation_type': 'patient_to_family',
      'invitation_code': invitationCode,
      'status': 'pending',
      'created_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    return InvitationModel.fromJson(response);
  }

  /// Create invitation from Family to Patient
  Future<InvitationModel> createInvitationFromFamily({
    required String familyMemberId,
    String? patientEmail,
    String? patientPhone,
  }) async {
    if (patientEmail == null && patientPhone == null) {
      throw Exception('Either patient email or phone must be provided');
    }

    String invitationCode = '';
    bool isUnique = false;
    
    // Ensure unique code
    while (!isUnique) {
      invitationCode = _generateInvitationCode();
      final existing = await _client
          .from('invitations')
          .select()
          .eq('invitation_code', invitationCode)
          .maybeSingle();
      isUnique = existing == null;
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    final response = await _client.from('invitations').insert({
      'family_member_id': familyMemberId,
      if (patientEmail != null) 'patient_email': patientEmail,
      if (patientPhone != null) 'patient_phone': patientPhone,
      'invitation_type': 'family_to_patient',
      'invitation_code': invitationCode,
      'status': 'pending',
      'created_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    return InvitationModel.fromJson(response);
  }

  /// Get invitation by code
  Future<InvitationModel?> getInvitationByCode(String code) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('invitation_code', code)
        .maybeSingle();

    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }

  /// Accept invitation
  Future<void> acceptInvitation(String code) async {
    await _client
        .from('invitations')
        .update({'status': 'accepted'})
        .eq('invitation_code', code);
  }

  /// Reject invitation
  Future<void> rejectInvitation(String code) async {
    await _client
        .from('invitations')
        .update({'status': 'rejected'})
        .eq('invitation_code', code);
  }

  /// Get all invitations for a patient
  Future<List<InvitationModel>> getInvitationsByPatient(String patientId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvitationModel.fromJson(json))
        .toList();
  }

  /// Get all invitations sent to a family member (by email or phone)
  Future<List<InvitationModel>> getInvitationsByFamily({
    String? email,
    String? phone,
  }) async {
    if (email == null && phone == null) {
      return [];
    }

    var query = _client.from('invitations').select();

    if (email != null && phone != null) {
      query = query.or('family_member_email.eq.$email,family_member_phone.eq.$phone');
    } else if (email != null) {
      query = query.eq('family_member_email', email);
    } else if (phone != null) {
      query = query.eq('family_member_phone', phone);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvitationModel.fromJson(json))
        .toList();
  }

  /// Get all invitations sent by a family member
  Future<List<InvitationModel>> getInvitationsByFamilyMember(String familyMemberId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('family_member_id', familyMemberId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InvitationModel.fromJson(json))
        .toList();
  }

  /// Mark expired invitations
  Future<void> markExpiredInvitations() async {
    final now = DateTime.now().toIso8601String();
    await _client
        .from('invitations')
        .update({'status': 'expired'})
        .eq('status', 'pending')
        .lt('expires_at', now);
  }
}

