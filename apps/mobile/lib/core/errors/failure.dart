/// Mây Family Finance — Error Model: Failure and Result
///
/// Consistent error model across Flutter (mobile) and TypeScript (Functions).
/// Maps to the ErrorCode enum from specs/06.

import 'package:flutter/foundation.dart';

/// Stable error codes matching ApiErrorDetail.code in contracts.
enum AppFailureCode {
  authRequired,          // user must re-login
  validation,            // invalid input (fieldErrors available)
  householdAccessDenied, // not a member of this tenant
  roleDenied,           // insufficient role (OWNER/ADMIN/EDITOR required)
  accountNotFound,      // referenced account does not exist in tenant
  currencyMismatch,     // different currencies attempted
  duplicateConflict,    // same clientRequestId with conflicting payload
  alreadyReversed,      // event has already been reversed
  receiptNotReady,      // OCR job not yet in REVIEW_REQUIRED state
  purchaseUnverified,   // store proof could not be verified
  rateLimited,          // too many requests; retry after backoff
  temporaryUnavailable, // server/service unavailable; exponential retry
  invariantFailed,      // internal consistency violation (sanitized)
}

/// A Failure value representing a transient or permanent error.
@immutable
sealed class Failure {
  final AppFailureCode code;
  final String message;
  final String correlationId;
  final bool retryable;
  final Map<String, String>? fieldErrors;

  const Failure({
    required this.code,
    required this.message,
    required this.correlationId,
    required this.retryable,
    this.fieldErrors,
  });

  bool get isRetryable => retryable;

  /// Returns the HttpsError detail code matching the backend API.
  String get detailCode {
    switch (code) {
      case AppFailureCode.authRequired:
        return 'AUTH_REQUIRED';
      case AppFailureCode.validation:
        return 'VALIDATION_ERROR';
      case AppFailureCode.householdAccessDenied:
        return 'HOUSEHOLD_ACCESS_DENIED';
      case AppFailureCode.roleDenied:
        return 'ROLE_DENIED';
      case AppFailureCode.accountNotFound:
        return 'ACCOUNT_NOT_FOUND';
      case AppFailureCode.currencyMismatch:
        return 'CURRENCY_MISMATCH';
      case AppFailureCode.duplicateConflict:
        return 'DUPLICATE_CONFLICT';
      case AppFailureCode.alreadyReversed:
        return 'ALREADY_REVERSED';
      case AppFailureCode.receiptNotReady:
        return 'RECEIPT_NOT_READY';
      case AppFailureCode.purchaseUnverified:
        return 'PURCHASE_UNVERIFIED';
      case AppFailureCode.rateLimited:
        return 'RATE_LIMITED';
      case AppFailureCode.temporaryUnavailable:
        return 'TEMPORARY_UNAVAILABLE';
      case AppFailureCode.invariantFailed:
        return 'INVARIANT_FAILED';
    }
  }

  @override
  String toString() => '${code.name}($message) [${correlationId}]';
}

/// Sealed Result type for explicit error handling.
/// Inspired by Rust's Result and Swift's Result.
@immutable
sealed class Result<T, F extends Failure> {
  const Result();

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T, F>;

  /// Returns true if this is a [Error].
  bool get isError => this is Error<F>;

  /// Wraps [error] as an Error.
  factory Result.error(F error) => Error(error) as Result<T, F>;

  /// Wraps [value] as a Success.
  factory Result.success(T value) => Success(value);

  /// The value if success, throws AssertionError if error.
  T get orThrow;

  /// Maps the failure to another type.
  R mapFailure<R>(R Function(F failure) onFailure);

  /// Maps the value if successful, returns null otherwise.
  T? getOrNull() {
    if (isSuccess) return (this as Success<T, F>).value;
    return null;
  }

  /// Returns the failure if error, null otherwise.
  F? getError() {
    if (isError) return (this as Error<F>).failure;
    return null;
  }
}

/// A successful Result containing a value of type [T].
@immutable
final class Success<T, F extends Failure> extends Result<T, F> {
  final T value;
  const Success(this.value);

  @override
  T get orThrow => value;

  @override
  R mapFailure<R>(R Function(F failure) onFailure) =>
      throw StateError('Cannot mapFailure on Success');
}

/// A failed Result containing a [Failure].
@immutable
final class Error<F extends Failure> extends Result<dynamic, F> {
  final F failure;
  const Error(this.failure);

  @override
  dynamic get orThrow => throw StateError(failure.toString());

  @override
  R mapFailure<R>(R Function(F failure) onFailure) => onFailure(failure);
}
