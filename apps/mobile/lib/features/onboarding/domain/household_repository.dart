/// Mây Family Finance — HouseholdRepository (onboarding domain layer)
///
/// Calls createHousehold Cloud Function (F01).
/// Per BR-02: if user already has a household, returns existing instead of erroring.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Supported household currency options for the UI pickers.
enum HouseholdCurrency { vnd, usd }

/// Repository for household creation and management.
class HouseholdRepository {
  static final instance = HouseholdRepository._();
  HouseholdRepository._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Create a new personal household via F01 createHousehold Cloud Function.
  ///
  /// Per BR-02: if user already has an existing household, the backend returns it
  /// rather than creating a duplicate — this method will throw only on unexpected errors.
  Future<Map<String, dynamic>> createHousehold({
    required String name,
    required HouseholdCurrency currency,
    required String timezone,
  }) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to create a household.');
    }

    final callable = _functions.httpsCallable('createHousehold');
    final result = await callable.call({
      'name': name,
      'currency': currency.name.toUpperCase(),
      'timezone': timezone,
      'clientRequestId': _generateIdempotentRequestId(user.uid),
    });

    // F01 response: { householdId, status: 'accepted', createdAtMs }
    final data = result.data as Map<String, dynamic>;
    if (data['status'] == 'error') {
      throw StateError(data['message'] ?? 'Unknown error creating household.');
    }

    return data;
  }

  /// Generate an idempotent request ID based on UID + timestamp.
  /// Production should use a UUID — Phase 1 placeholder using epoch ms.
  String _generateIdempotentRequestId(String uid) {
    return '${uid}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
