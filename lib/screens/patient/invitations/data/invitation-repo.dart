import 'package:alzcare/core/models/invitation-model.dart';
import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/invitation-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:dartz/dartz.dart';

class InvitationRepo {
  final InvitationService _invitationService;
  final PatientFamilyService _patientFamilyService;
  final UserService _userService;
  final AuthService _authService;
  final PatientService _patientService;

  InvitationRepo(
    this._invitationService,
    this._patientFamilyService,
    this._userService,
    this._authService,
    this._patientService,
  );

  /// Create invitation (Patient to Family)
  Future<Either<String, InvitationModel>> createInvitation({
    required String patientId,
    String? familyMemberEmail,
    String? familyMemberPhone,
  }) async {
    try {
      final invitation = await _invitationService.createInvitation(
        patientId: patientId,
        familyMemberEmail: familyMemberEmail,
        familyMemberPhone: familyMemberPhone,
      );
      return Right(invitation);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Create invitation from Family to Patient
  /// Automatically creates patient account if email doesn't exist
  /// Links patient to family immediately
  Future<Either<String, InvitationModel>> createInvitationFromFamily({
    required String familyMemberId,
    required String patientEmail,
    String? patientPhone,
    required String patientName,
  }) async {
    try {
      // Check if patient exists by email
      String? patientUserId;
      String? patientRecordId;
      final existingUser = await _userService.getUserByEmail(patientEmail);
      
      if (existingUser != null) {
        // Patient exists, use their ID
        if (existingUser['role'] == 'patient') {
          patientUserId = existingUser['id'] as String;
          // Get patient record ID from patients table
          final patientRecord = await _patientService.getPatientByUserId(patientUserId);
          if (patientRecord != null) {
            patientRecordId = patientRecord['id'] as String?;
          } else {
            // User exists but no patient record, create it
            await _patientService.addPatient(
              patientId: patientUserId,
              age: 0,
              name: patientName,
              gender: 'Male', // Use 'Male' or 'Female' as per the dropdown
            );
            final newPatientRecord = await _patientService.getPatientByUserId(patientUserId);
            patientRecordId = newPatientRecord?['id'] as String?;
          }
        } else {
          return const Left('Email is already registered with a different role');
        }
      } else {
        // Patient doesn't exist, create new account
        try {
          final authResponse = await _authService.createPatientAccountWithDefaultPassword(
            email: patientEmail,
            name: patientName,
            phone: patientPhone,
          );

          if (authResponse.user == null) {
            return const Left('Failed to create patient account');
          }

          patientUserId = authResponse.user!.id;

          // Create patient record with minimal data (addPatient checks if exists)
          // Note: gender must be 'Male' or 'Female' (capitalized) as per the dropdown
          await _patientService.addPatient(
            patientId: patientUserId,
            age: 0, // Will be updated later
            name: patientName,
            gender: 'Male', // Default value, will be updated later
          );
          
          // Get the patient record ID
          final patientRecord = await _patientService.getPatientByUserId(patientUserId);
          patientRecordId = patientRecord?['id'] as String?;
        } catch (e) {
          // If account creation fails (e.g., email already exists in auth)
          // Check if user exists in users table by email
          final userByEmail = await _userService.getUserByEmail(patientEmail);
          if (userByEmail != null) {
            // User exists, use their ID
            patientUserId = userByEmail['id'] as String;
            final patientRecord = await _patientService.getPatientByUserId(patientUserId);
            if (patientRecord != null) {
              patientRecordId = patientRecord['id'] as String?;
            } else {
              // Create patient record (addPatient checks if exists)
              await _patientService.addPatient(
                patientId: patientUserId,
                age: 0,
                name: patientName,
                gender: 'Male',
              );
              final newPatientRecord = await _patientService.getPatientByUserId(patientUserId);
              patientRecordId = newPatientRecord?['id'] as String?;
            }
          } else {
            // Email exists in auth but not in users table - this is a problem
            return Left('Email is already registered in the system but account setup is incomplete. Please contact support or try a different email.');
          }
        }
      }

      if (patientRecordId == null) {
        return const Left('Failed to get patient record ID');
      }

      // Create invitation (initially without patient_id to avoid FK issues).
      // Afterwards we will try to back-fill invitations.patient_id safely.
      final invitation = await _invitationService.createInvitationFromFamily(
        familyMemberId: familyMemberId,
        patientEmail: patientEmail,
        patientPhone: patientPhone,
      );

      // Try to set invitations.patient_id with the patient record id.
      // If there is a foreign key mismatch or any DB constraint, we ignore
      // the error and keep the invitation (linking is still handled via
      // patient_family_relations and email/phone).
      final invitationId = invitation.id;
      if (invitationId != null) {
        try {
          await SupabaseConfig.client
              .from('invitations')
              .update({'patient_id': patientRecordId})
              .eq('id', invitationId);
        } catch (e) {
          // Log a warning but don't fail the flow
          final msg = SupabaseErrorHandler.handleError(e);
          // ignore: avoid_print
          print('Warning: failed to update invitations.patient_id: $msg');
        }
      }

      // Link patient to family immediately using the *patient record id only*.
      // This guarantees that patient_family_relations.patient_id always points
      // to patients.id (وليس users.id) حتى لا يحدث لخبطة فى الداتابيز.
      try {
        final relationExists = await _patientFamilyService.relationExists(
          patientId: patientRecordId,
          familyMemberId: familyMemberId,
        );

        if (!relationExists) {
          await _patientFamilyService.linkPatientToFamily(
            patientId: patientRecordId,
            familyMemberId: familyMemberId,
          );
        }
      } catch (e) {
        // لو الربط فشل لأى سبب، نسجل تحذير لكن مانفشلش عملية الإنفتيشن.
        final msg = SupabaseErrorHandler.handleError(e);
        // ignore: avoid_print
        print(
            'Warning: Failed to link patient to family automatically (record id). $msg');
      }

      return Right(invitation);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Get invitation by code
  Future<Either<String, InvitationModel?>> getInvitationByCode(
      String code) async {
    try {
      final invitation = await _invitationService.getInvitationByCode(code);
      return Right(invitation);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Accept invitation and link patient to family
  /// Supports both Patient-to-Family and Family-to-Patient invitations
  Future<Either<String, void>> acceptInvitation({
    required String invitationCode,
    required String patientId, // This is user_id, need to convert to patient record ID
  }) async {
    try {
      // Get invitation
      final invitation = await _invitationService.getInvitationByCode(invitationCode);
      if (invitation == null) {
        return const Left('Invitation not found');
      }

      // Allow accepting even if already accepted (for re-linking or navigation)
      // Only block if rejected or expired
      if (invitation.status == 'rejected') {
        return const Left('Invitation has been rejected');
      }

      if (invitation.isExpired && invitation.status != 'accepted') {
        return const Left('Invitation has expired');
      }

      // Convert user_id to patient record ID
      // patientId parameter هو user_id، لكن فى جدول العلاقات نريد دائمًا patients.id
      Map<String, dynamic>? patientRecord =
          await _patientService.getPatientByUserId(patientId);
      String? finalPatientId;

      if (patientRecord == null || patientRecord['id'] == null) {
        // لو مفيش record فى جدول patients، ننشئ واحد بسيط ونرجع الـ id.
        await _patientService.addPatient(
          patientId: patientId,
          age: 0,
          name: 'Patient',
          gender: 'Male',
        );
        patientRecord = await _patientService.getPatientByUserId(patientId);
      }

      finalPatientId = patientRecord?['id'] as String?;
      if (finalPatientId == null) {
        return const Left('Failed to resolve patient record ID');
      }

      // Determine invitation type
      final isFamilyToPatient = invitation.isFamilyToPatient;

      String? familyMemberId;

      if (isFamilyToPatient) {
        // Family-to-Patient invitation: use familyMemberId from invitation
        if (invitation.familyMemberId != null) {
          familyMemberId = invitation.familyMemberId;
        } else {
          return const Left('Family member ID not found in invitation');
        }
      } else {
        // Patient-to-Family invitation: find family member by email or phone
        if (invitation.familyMemberEmail != null) {
          final users = await _userService.getUserByEmail(invitation.familyMemberEmail!);
          if (users != null && users['role'] == 'family') {
            familyMemberId = users['id'];
          }
        }

        if (familyMemberId == null && invitation.familyMemberPhone != null) {
          // Try to find by phone if needed
          // Note: This requires a phone field in users table or separate lookup
        }

        if (familyMemberId == null) {
          return const Left('Family member not found. Please ensure they have registered.');
        }
      }

      // At this point, familyMemberId must be non-null
      final finalFamilyMemberId = familyMemberId!;

      // Check if relation already exists
      final exists = await _patientFamilyService.relationExists(
        patientId: finalPatientId,
        familyMemberId: finalFamilyMemberId,
      );

      if (exists) {
        // Mark invitation as accepted even if relation exists
        await _invitationService.acceptInvitation(invitationCode);
        return const Right(null);
      }

      // Link patient to family using patient record ID
      await _patientFamilyService.linkPatientToFamily(
        patientId: finalPatientId,
        familyMemberId: finalFamilyMemberId,
      );

      // Mark invitation as accepted
      await _invitationService.acceptInvitation(invitationCode);

      return const Right(null);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Reject invitation
  Future<Either<String, void>> rejectInvitation(String code) async {
    try {
      await _invitationService.rejectInvitation(code);
      return const Right(null);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Get invitations by patient
  Future<Either<String, List<InvitationModel>>> getInvitationsByPatient(
      String patientId) async {
    try {
      final invitations = await _invitationService.getInvitationsByPatient(patientId);
      return Right(invitations);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Get invitations by family member (received invitations)
  Future<Either<String, List<InvitationModel>>> getInvitationsByFamily({
    String? email,
    String? phone,
  }) async {
    try {
      final invitations = await _invitationService.getInvitationsByFamily(
        email: email,
        phone: phone,
      );
      return Right(invitations);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }

  /// Get invitations sent by a family member
  Future<Either<String, List<InvitationModel>>> getInvitationsByFamilyMember(
    String familyMemberId,
  ) async {
    try {
      if (familyMemberId.isEmpty) {
        return const Left('Family member ID is required');
      }
      final invitations = await _invitationService.getInvitationsByFamilyMember(familyMemberId);
      return Right(invitations);
    } catch (e) {
      return Left(SupabaseErrorHandler.handleError(e));
    }
  }
}



