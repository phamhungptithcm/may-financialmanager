/// Mây Family Finance — Unit Tests: Failure + Result types
///
/// Tests for error model and sealed Result type covering happy path,
/// negative cases, edge conditions and security invariants.

import 'package:flutter_test/flutter_test.dart';
import 'package:may/core/errors/failure.dart';

void main() {
  // ================================================================
  // AppFailureCode — completeness check
  // ================================================================
  group('AppFailureCode', () {
    test('all expected codes exist', () {
      expect(AppFailureCode.authRequired, isNotNull);
      expect(AppFailureCode.validation, isNotNull);
      expect(AppFailureCode.householdAccessDenied, isNotNull);
      expect(AppFailureCode.roleDenied, isNotNull);
      expect(AppFailureCode.accountNotFound, isNotNull);
      expect(AppFailureCode.currencyMismatch, isNotNull);
      expect(AppFailureCode.duplicateConflict, isNotNull);
      expect(AppFailureCode.alreadyReversed, isNotNull);
      expect(AppFailureCode.receiptNotReady, isNotNull);
      expect(AppFailureCode.purchaseUnverified, isNotNull);
      expect(AppFailureCode.rateLimited, isNotNull);
      expect(AppFailureCode.temporaryUnavailable, isNotNull);
      expect(AppFailureCode.invariantFailed, isNotNull);
    });

    test('total count matches expected', () {
      // 13 values — keep in sync with failure.dart enum
      final values = AppFailureCode.values;
      expect(values.length, equals(13));
    });
  });

  // ================================================================
  // Failure — Happy Path (construction)
  // ================================================================
  group('Failure', () {
    test('authRequired Failure construction', () {
      const failure = Failure(
        code: AppFailureCode.authRequired,
        message: 'Please log in again.',
        correlationId: 'corr_abc123',
        retryable: true,
      );

      expect(failure.code, equals(AppFailureCode.authRequired));
      expect(failure.message, equals('Please log in again.'));
      expect(failure.correlationId, equals('corr_abc123'));
      expect(failure.isRetryable, isTrue);
    });

    test('validation Failure with fieldErrors', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Invalid input.',
        correlationId: 'corr_def456',
        retryable: false,
        fieldErrors: {'name': 'Required', 'email': 'Invalid format'},
      );

      expect(failure.code, equals(AppFailureCode.validation));
      expect(failure.fieldErrors!['name'], equals('Required'));
    });

    test('Failure with null fieldErrors', () {
      const failure = Failure(
        code: AppFailureCode.temporaryUnavailable,
        message: 'Service unavailable.',
        correlationId: 'corr_null_field',
        retryable: true,
      );

      expect(failure.fieldErrors, isNull);
    });

    test('toString includes code name, message and correlationId', () {
      const failure = Failure(
        code: AppFailureCode.householdAccessDenied,
        message: 'Access denied to household.',
        correlationId: 'corr_abc',
        retryable: false,
      );

      final str = failure.toString();
      expect(str, contains('householdAccessDenied'));
      expect(str, contains('Access denied to household.'));
      expect(str, contains('corr_abc'));
    });
  });

  // ================================================================
  // Failure — detailCode mapping (all codes)
  // ================================================================
  group('Failure.detailCode', () {
    test('authRequired => AUTH_REQUIRED', () {
      const failure = Failure(
        code: AppFailureCode.authRequired,
        message: 'Login required.',
        correlationId: 'corr',
        retryable: true,
      );
      expect(failure.detailCode, equals('AUTH_REQUIRED'));
    });

    test('validation => VALIDATION_ERROR', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Bad input.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('VALIDATION_ERROR'));
    });

    test('householdAccessDenied => HOUSEHOLD_ACCESS_DENIED', () {
      const failure = Failure(
        code: AppFailureCode.householdAccessDenied,
        message: 'Not a member.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('HOUSEHOLD_ACCESS_DENIED'));
    });

    test('roleDenied => ROLE_DENIED', () {
      const failure = Failure(
        code: AppFailureCode.roleDenied,
        message: 'Insufficient role.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('ROLE_DENIED'));
    });

    test('accountNotFound => ACCOUNT_NOT_FOUND', () {
      const failure = Failure(
        code: AppFailureCode.accountNotFound,
        message: 'Account missing.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('ACCOUNT_NOT_FOUND'));
    });

    test('currencyMismatch => CURRENCY_MISMATCH', () {
      const failure = Failure(
        code: AppFailureCode.currencyMismatch,
        message: 'Currency mismatch.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('CURRENCY_MISMATCH'));
    });

    test('duplicateConflict => DUPLICATE_CONFLICT', () {
      const failure = Failure(
        code: AppFailureCode.duplicateConflict,
        message: 'Already exists.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('DUPLICATE_CONFLICT'));
    });

    test('alreadyReversed => ALREADY_REVERSED', () {
      const failure = Failure(
        code: AppFailureCode.alreadyReversed,
        message: 'Already reversed.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('ALREADY_REVERSED'));
    });

    test('receiptNotReady => RECEIPT_NOT_READY', () {
      const failure = Failure(
        code: AppFailureCode.receiptNotReady,
        message: 'OCR not ready.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('RECEIPT_NOT_READY'));
    });

    test('purchaseUnverified => PURCHASE_UNVERIFIED', () {
      const failure = Failure(
        code: AppFailureCode.purchaseUnverified,
        message: 'Purchase unverified.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('PURCHASE_UNVERIFIED'));
    });

    test('rateLimited => RATE_LIMITED', () {
      const failure = Failure(
        code: AppFailureCode.rateLimited,
        message: 'Rate limited.',
        correlationId: 'corr',
        retryable: true,
      );
      expect(failure.detailCode, equals('RATE_LIMITED'));
    });

    test('temporaryUnavailable => TEMPORARY_UNAVAILABLE', () {
      const failure = Failure(
        code: AppFailureCode.temporaryUnavailable,
        message: 'Service unavailable.',
        correlationId: 'corr',
        retryable: true,
      );
      expect(failure.detailCode, equals('TEMPORARY_UNAVAILABLE'));
    });

    test('invariantFailed => INVARIANT_FAILED', () {
      const failure = Failure(
        code: AppFailureCode.invariantFailed,
        message: 'Invariant violated.',
        correlationId: 'corr',
        retryable: false,
      );
      expect(failure.detailCode, equals('INVARIANT_FAILED'));
    });

    test('all 13 codes have detail mappings', () {
      for (final code in AppFailureCode.values) {
        final failure = Failure(
          code: code,
          message: 'Test',
          correlationId: 'corr',
          retryable: false,
        );
        expect(failure.detailCode, isNotEmpty, reason: '$code should map to non-empty detail');
      }
    });
  });

  // ================================================================
  // Result — Happy Path (Success)
  // ================================================================
  group('Result — Success', () {
    test('creates Success with value', () {
      final result = Result<String, Failure>.success('hello');
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
    });

    test('orThrow returns the wrapped value', () {
      final result = Result<String, Failure>.success('world');
      expect(result.orThrow, equals('world'));
    });

    test('getOrNull returns the value', () {
      final result = Result<String, Failure>.success('data');
      expect(result.getOrNull(), equals('data'));
    });

    test('getError returns null for Success', () {
      final result = Result<String, Failure>.success('data');
      expect(result.getError(), isNull);
    });

    test('mapFailure throws StateError on Success', () {
      final result = Result<String, Failure>.success('value');
      expect(
        () => result.mapFailure((f) => 'mapped'),
        throwsA(isA<StateError>()),
      );
    });

    test('Success is immutable (const constructor)', () {
      const a = Success('test', Failure(
        code: AppFailureCode.validation,
        message: 'Err',
        correlationId: 'c',
        retryable: false,
      ));
      const b = Success('test', Failure(
        code: AppFailureCode.validation,
        message: 'Err',
        correlationId: 'c',
        retryable: false,
      ));
      expect(a.value, equals(b.value)); // value equality (Success is not const-equal)
    });
  });

  // ================================================================
  // Result — Happy Path (Error)
  // ================================================================
  group('Result — Error', () {
    test('creates Error with failure', () {
      const failure = Failure(
        code: AppFailureCode.authRequired,
        message: 'Login required.',
        correlationId: 'corr_1',
        retryable: true,
      );
      final result = Result<String, Failure>.error(failure);
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('orThrow throws StateError on Error', () {
      const failure = Failure(
        code: AppFailureCode.temporaryUnavailable,
        message: 'Down.',
        correlationId: 'corr_2',
        retryable: true,
      );
      final result = Result<String, Failure>.error(failure);
      expect(
        () => result.orThrow,
        throwsA(isA<StateError>()),
      );
    });

    test('mapFailure invokes handler on Error', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Bad input.',
        correlationId: 'corr_3',
        retryable: false,
      );
      final result = Result<int, Failure>.error(failure);

      final mapped = result.mapFailure((f) => f.code.name);
      expect(mapped, equals('validation'));
    });

    test('getError returns the failure on Error', () {
      const failure = Failure(
        code: AppFailureCode.roleDenied,
        message: 'Insufficient role.',
        correlationId: 'corr_4',
        retryable: false,
      );
      final result = Result<String, Failure>.error(failure);
      expect(result.getError(), equals(failure));
    });

    test('getOrNull returns null on Error', () {
      const failure = Failure(
        code: AppFailureCode.accountNotFound,
        message: 'Missing.',
        correlationId: 'corr_5',
        retryable: false,
      );
      final result = Result<String, Failure>.error(failure);
      expect(result.getOrNull(), isNull);
    });

    test('mapFailure returns correct type (String)', () {
      const failure = Failure(
        code: AppFailureCode.duplicateConflict,
        message: 'Conflict.',
        correlationId: 'corr_6',
        retryable: false,
      );
      final result = Result<String, Failure>.error(failure);

      // mapFailure returns a string description of the failure
      final mapped = result.mapFailure((f) => '${f.code.name}: ${f.message}');
      expect(mapped, contains('duplicateConflict'));
    });

    test('mapFailure returns correct type (int count)', () {
      const failure = Failure(
        code: AppFailureCode.rateLimited,
        message: 'Too many.',
        correlationId: 'corr_7',
        retryable: true,
      );
      final result = Result<String, Failure>.error(failure);

      // mapFailure returns a count (demonstrates generic return type)
      final mapped = result.mapFailure((f) => f.message.length);
      expect(mapped, equals(8));
    });
  });

  // ================================================================
  // Result — Negative Cases
  // ================================================================
  group('Result — negative cases', () {
    test('mapFailure on Success with complex type throws', () {
      final result = Result<List<int>, Failure>.success([1, 2, 3]);
      expect(
        () => result.mapFailure((f) => f.detailCode),
        throwsA(isA<StateError>()),
      );
    });

    test('orThrow on Error preserves correlationId in message', () {
      const failure = Failure(
        code: AppFailureCode.invariantFailed,
        message: 'Invariant broken.',
        correlationId: 'corr_verify_id',
        retryable: false,
      );
      final result = Result<String, Failure>.error(failure);

      try {
        _ = result.orThrow;
        fail('Expected StateError to be thrown');
      } catch (e) {
        expect(e.toString(), contains('corr_verify_id'));
        expect(e.toString(), contains('Invariant broken.'));
      }
    });
  });

  // ================================================================
  // Result — Edge / Boundary Conditions
  // ================================================================
  group('Result — edge conditions', () {
    test('Success with null-like values (zero, empty string)', () {
      final intSuccess = Result<int, Failure>.success(0);
      expect(intSuccess.orThrow, equals(0));

      final strSuccess = Result<String, Failure>.success('');
      expect(strSuccess.orThrow, equals(''));

      final listSuccess = Result<List<int>, Failure>.success([]);
      expect(listSuccess.getOrNull(), isEmpty);
    });

    test('Failure with empty message', () {
      const failure = Failure(
        code: AppFailureCode.temporaryUnavailable,
        message: '',
        correlationId: 'corr_empty_msg',
        retryable: true,
      );
      expect(failure.message, equals(''));
      // toString should still work
      final str = failure.toString();
      expect(str, contains('temporaryUnavailable'));
    });

    test('Failure with empty correlationId', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Error.',
        correlationId: '',
        retryable: false,
      );
      expect(failure.toString(), contains('[]'));
    });

    test('Failure with long correlationId', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Error.',
        correlationId: 'corr_${'a' * 200}',
        retryable: false,
      );
      expect(failure.toString(), contains('corr_'));
    });

    test('isRetryable mirrors retryable field', () {
      const r1 = Failure(
        code: AppFailureCode.temporaryUnavailable,
        message: 'Retriable.',
        correlationId: 'c1',
        retryable: true,
      );
      expect(r1.isRetryable, isTrue);

      const r2 = Failure(
        code: AppFailureCode.validation,
        message: 'Not retriable.',
        correlationId: 'c2',
        retryable: false,
      );
      expect(r2.isRetryable, isFalse);
    });
  });

  // ================================================================
  // Result — Type Safety / Invariants
  // ================================================================
  group('Result — type safety invariants', () {
    test('Success.orThrow never throws', () {
      final result = Result<String, Failure>.success('safe_value');
      expect(result.orThrow, equals('safe_value'));
      expect(() => result.orThrow, returnsNormally);
    });

    test('Error.orThrow always throws', () {
      const failure = Failure(
        code: AppFailureCode.authRequired,
        message: 'Auth required.',
        correlationId: 'corr_auth',
        retryable: true,
      );
      final result = Result<String, Failure>.error(failure);
      expect(() => result.orThrow, throwsA(isA<StateError>()));
    });

    test('mapFailure on Success never returns the handler result', () {
      final result = Result<String, Failure>.success('value');
      int callCount = 0;
      final mapped = result.mapFailure((f) {
        callCount++;
        return 'never';
      });
      expect(callCount, equals(0)); // handler was NOT called
    });

    test('mapFailure on Error always calls the handler', () {
      const failure = Failure(
        code: AppFailureCode.receiptNotReady,
        message: 'OCR pending.',
        correlationId: 'corr_ocr',
        retryable: false,
      );
      final result = Result<String, Failure>.error(failure);
      int callCount = 0;
      final mapped = result.mapFailure((f) {
        callCount++;
        return f.code.name.length;
      });
      expect(callCount, equals(1)); // handler WAS called
    });

    test('Success.getOrNull returns Some, Error.getOrNull returns null', () {
      final successResult = Result<String, Failure>.success('data');
      expect(successResult.getOrNull(), equals('data'));

      const failure = Failure(
        code: AppFailureCode.accountNotFound,
        message: 'Not found.',
        correlationId: 'corr_miss',
        retryable: false,
      );
      final errorResult = Result<String, Failure>.error(failure);
      expect(errorResult.getOrNull(), isNull);
    });

    test('Error.getError returns Some, Success.getError returns null', () {
      const failure = Failure(
        code: AppFailureCode.purchaseUnverified,
        message: 'Proof missing.',
        correlationId: 'corr_proof',
        retryable: false,
      );
      final errorResult = Result<String, Failure>.error(failure);
      expect(errorResult.getError(), equals(failure));

      final successResult = Result<String, Failure>.success('verified');
      expect(successResult.getError(), isNull);
    });
  });

  // ================================================================
  // Security — Failure injection prevention
  // ================================================================
  group('Security — failure invariants', () {
    test('detailCode never returns empty string', () {
      for (final code in AppFailureCode.values) {
        final failure = Failure(
          code: code,
          message: 'Test',
          correlationId: 'corr_sec',
          retryable: false,
        );
        expect(failure.detailCode.isNotEmpty, isTrue);
        // All detail codes should be uppercase (security: never expose lowercase which could match internal flags)
        expect(failure.detailCode, equals(failure.detailCode.toUpperCase()));
      }
    });

    test('correlationId is never null in Failure', () {
      for (final code in AppFailureCode.values) {
        final failure = Failure(
          code: code,
          message: 'Test',
          correlationId: 'corr_id_${code.name}',
          retryable: false,
        );
        expect(failure.correlationId.isNotEmpty, isTrue);
      }
    });

    test('fieldErrors with special characters does not crash toString', () {
      const failure = Failure(
        code: AppFailureCode.validation,
        message: 'Invalid.',
        correlationId: 'corr_special',
        retryable: false,
        fieldErrors: {'<script>': 'XSS attempt', 'name": "'; /*: evil*/}: 'attack'},
      );
      expect(() => failure.toString(), returnsNormally);
    });

    test('Result with many nested Error values works correctly', () {
      const innerFailure = Failure(
        code: AppFailureCode.invariantFailed,
        message: 'Deep error.',
        correlationId: 'corr_deep',
        retryable: false,
      );
      // Result inside a list wrapped in Result
      final result = Result<List<String>, Failure>.error(innerFailure);
      expect(result.isError, isTrue);
      expect(result.getError()!.code, equals(AppFailureCode.invariantFailed));
    });
  });
}
