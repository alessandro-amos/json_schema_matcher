import 'package:test/expect.dart';

/// Creates a matcher for JSON objects validation using standard Dart matchers.
///
/// The [strictFields] parameter, when set to true, makes the matcher
/// fail if the object contains fields not defined in [fieldMatchers].
/// Defaults to false.
///
/// Example:
/// ```dart
/// expect(userData, isJsonObject({
///   'name': isA<String>(),
///   'age': isA<int>(),
///   'email': anyOf([isA<String>(), isNull]),
///   'status': isIn(['active', 'inactive', 'pending']),
/// }));
/// ```
Matcher isJsonObject(
  Map<String, Matcher> fieldMatchers, {
  bool strictFields = false,
}) => _JsonSchemaMatcher(
  _jsonObjectWithMatchers(fieldMatchers, strictFields: strictFields),
);

/// Creates a matcher for JSON arrays of objects validation using standard Dart matchers.
///
/// The [strictFields] parameter, when set to true, makes the matcher
/// fail if any object in the array contains fields not defined in [itemFieldMatchers].
/// Defaults to false.
///
/// Example:
/// ```dart
/// expect(usersList, isJsonArray({
///   'id': isA<int>(),
///   'name': isA<String>(),
///   'active': isA<bool>(),
///   'role': isIn(['admin', 'user']),
/// }));
/// ```
Matcher isJsonArray(
  Map<String, Matcher> itemFieldMatchers, {
  bool strictFields = false,
}) => _JsonSchemaMatcher(
  _jsonArrayWithMatchers(itemFieldMatchers, strictFields: strictFields),
);

/// Creates a matcher for JSON arrays of primitive types validation using a matcher.
///
/// Example:
/// ```dart
/// expect(['tag1', 'tag2'], isJsonArrayOf(isA<String>()));
/// expect(['active', 'done'], isJsonArrayOf(isIn(['active', 'pending', 'done'])));
/// expect([1, null, 3], isJsonArrayOf(anyOf([isA<int>(), isNull])));
/// ```
Matcher isJsonArrayOf(Matcher itemMatcher) => _JsonSchemaMatcher(
  _jsonArrayOfMatcher(itemMatcher),
);

/// Function that validates a value against a JSON schema.
///
/// Receives the [value] to be validated, the current [path] in the object
/// (for error reporting) and a list of [errors] where validation messages are added.
typedef Validator =
    void Function(
      dynamic value,
      String path,
      List<String> errors,
    );

/// Creates a validator from a standard Dart matcher.
///
/// Converts any [Matcher] into a validator function that can be used
/// for JSON schema validation with proper error reporting and path tracking.
Validator _matcherToValidator(Matcher matcher) {
  return (value, path, errors) {
    final matchState = <String, dynamic>{};
    if (!matcher.matches(value, matchState)) {
      if (matcher is _JsonSchemaMatcher) {
        matcher.validator(value, path, errors);
      } else {
        final mismatchDescription = StringDescription();
        matcher.describeMismatch(value, mismatchDescription, matchState, false);

        String errorMessage = mismatchDescription.toString().trim();

        if (errorMessage.isEmpty) {
          final expectedDescription = StringDescription();
          matcher.describe(expectedDescription);
          final expected = expectedDescription.toString();

          // Create a more descriptive error message
          if (expected.isNotEmpty) {
            errorMessage = 'does not match $expected (got: $value)';
          } else {
            errorMessage = 'validation failed (got: $value)';
          }
        }

        errors.add('Field $path: $errorMessage');
      }
    }
  };
}

/// Creates a validator for JSON objects with specific fields using matchers.
///
/// The [fieldMatchers] parameter maps field names to their matchers.
/// Use standard Dart matchers like [isA], [equals], [anything], etc.
///
/// The [strictFields] parameter, when set to true, makes the validator
/// fail if the object contains fields not defined in [fieldMatchers].
/// Defaults to false.
Validator _jsonObjectWithMatchers(
  Map<String, Matcher> fieldMatchers, {
  bool strictFields = false,
}) {
  final fieldValidators = fieldMatchers.map(
    (key, matcher) => MapEntry(key, _matcherToValidator(matcher)),
  );

  return (value, path, errors) {
    if (value is! Map) {
      errors.add(
        'Field $path: has invalid type '
        '(expected Map, received ${value.runtimeType})',
      );
      return;
    }

    for (final entry in fieldValidators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final fieldPath = _buildFieldPath(path, fieldName);

      if (!value.containsKey(fieldName)) {
        final testErrors = <String>[];
        validator(null, 'test', testErrors);
        if (testErrors.isNotEmpty) {
          errors.add('Field $fieldPath: is required');
        }
      } else {
        validator(value[fieldName], fieldPath, errors);
      }
    }

    if (strictFields) {
      for (final key in value.keys) {
        if (!fieldValidators.containsKey(key)) {
          final fieldPath = _buildFieldPath(path, key.toString());
          errors.add('Field $fieldPath: is not expected');
        }
      }
    }
  };
}

/// Creates a validator for JSON arrays where each item follows a specific schema using matchers.
///
/// The [itemFieldMatchers] parameter defines the matchers for each field
/// of the objects within the array.
///
/// The [strictFields] parameter, when set to true, makes the validator
/// fail if any object in the array contains fields not defined in [itemFieldMatchers].
/// Defaults to false.
Validator _jsonArrayWithMatchers(
  Map<String, Matcher> itemFieldMatchers, {
  bool strictFields = false,
}) {
  return (value, path, errors) {
    if (value is! List) {
      errors.add(
        'Field $path: has invalid type '
        '(expected List, received ${value.runtimeType})',
      );
      return;
    }

    for (int i = 0; i < value.length; i++) {
      final itemPath = _buildIndexPath(path, i);
      final item = value[i];

      if (item is! Map) {
        errors.add(
          'Item $itemPath has invalid type '
          '(expected Map, received ${item.runtimeType})',
        );
        continue;
      }

      final objectValidator = _jsonObjectWithMatchers(
        itemFieldMatchers,
        strictFields: strictFields,
      );
      objectValidator(item, itemPath, errors);
    }
  };
}

/// Creates a validator for JSON arrays of primitive types using a matcher.
///
/// Unlike [_jsonArrayWithMatchers], this validates arrays of primitive values directly,
/// not arrays of objects.
Validator _jsonArrayOfMatcher(Matcher itemMatcher) {
  final itemValidator = _matcherToValidator(itemMatcher);

  return (value, path, errors) {
    if (value is! List) {
      errors.add(
        'Field $path: has invalid type '
        '(expected List, received ${value.runtimeType})',
      );
      return;
    }

    for (int i = 0; i < value.length; i++) {
      final itemPath = _buildIndexPath(path, i);
      final item = value[i];
      itemValidator(item, itemPath, errors);
    }
  };
}

/// Builds the path of a field for error reporting.
/// Uses bracket notation: [field1][field2]
String _buildFieldPath(String basePath, String fieldName) {
  return '$basePath[$fieldName]';
}

/// Builds the path of an array index for error reporting.
/// Uses bracket notation: [0], [1], etc.
String _buildIndexPath(String basePath, int index) {
  return '$basePath[$index]';
}

/// Custom matcher for JSON schema validation using Dart's testing framework.
///
/// This matcher uses a [Validator] to check if a JSON object
/// follows a specific schema, providing detailed error messages
/// in case of validation failure.
class _JsonSchemaMatcher extends Matcher {
  /// The validator that will be used to verify the schema.
  final Validator validator;

  /// Creates a new [_JsonSchemaMatcher] with the specified [validator].
  const _JsonSchemaMatcher(this.validator);

  @override
  bool matches(item, Map matchState) {
    final errors = <String>[];
    validator(item, '', errors);

    if (errors.isNotEmpty) {
      matchState['errors'] = errors;
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('matches JSON schema');
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final errors = matchState['errors'] as List<String>?;
    if (errors != null && errors.isNotEmpty) {
      mismatchDescription.add('does not match JSON schema');
      for (var error in errors) {
        mismatchDescription.add('\n- ').add(error);
      }
    }
    return mismatchDescription;
  }
}
