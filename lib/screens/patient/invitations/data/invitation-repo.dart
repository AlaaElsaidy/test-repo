import 'package:alzcare/core/models/invitation-model.dart';
import 'package:alzcare/core/supabase/invitation-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-error-handler.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:dartz/dartz.dart';

class InvitationRepo {
  final InvitationService _invitationService;
  final PatientFamilyService _patientFamilyService;
  final UserService _userService;

  InvitationRepo(
    this._invitationService,
    this._patientFamilyService,
    this._userService,
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
  Future<Either<String, InvitationModel>> createInvitationFromFamily({
    required String familyMemberId,
    String? patientEmail,
    String? patientPhone,
  }) async {
    try {
      final invitation = await _invitationService.createInvitationFromFamily(
        familyMemberId: familyMemberId,
        patientEmail: patientEmail,
        patientPhone: patientPhone,
      );
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
    required String patientId,
  }) async {
    try {
      // Get invitation
      final invitation = await _invitationService.getInvitationByCode(invitationCode);
      if (invitation == null) {
        return const Left('Invitation not found');
      }

      if (invitation.status != 'pending') {
        return Left('Invitation is already ${invitation.status}');
      }

      if (invitation.isExpired) {
        return const Left('Invitation has expired');
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
        patientId: patientId,
        familyMemberId: finalFamilyMemberId,
      );

      if (exists) {
        // Mark invitation as accepted even if relation exists
        await _invitationService.acceptInvitation(invitationCode);
        return const Right(null);
      }

      // Link patient to family
      await _patientFamilyService.linkPatientToFamily(
        patientId: patientId,
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



