import 'package:test/expect.dart';

/// Function that validates a value against a JSON schema.
///
/// Receives the [value] to be validated, the current [path] in the object
/// (for error reporting) and a list of [errors] where validation messages are added.
typedef Validator =
    void Function(dynamic value, String path, List<String> errors);

/// Creates a validator that checks if the value is of type [T].
///
/// Supports nullable types - if [T] is nullable (like `String?`),
/// accepts `null` values.
///
/// Example:
/// ```dart
/// final stringValidator = typeOf<String>();
/// final nullableIntValidator = typeOf<int?>();
/// ```
Validator typeOf<T>() {
  return (value, path, errors) {
    final isNullable = null is T;

    if (value == null && isNullable) {
      return;
    }

    if (value is! T) {
      final expectedType = T.toString();
      final actualType = value.runtimeType.toString();
      errors.add(
        'Field $path has invalid type '
        '(expected $expectedType, received $actualType)',
      );
    }
  };
}

/// Checks if a validator accepts null values.
///
/// Used internally to determine if a field is required.
bool _validatorAcceptsNull(Validator validator) {
  final testErrors = <String>[];
  validator(null, 'test', testErrors);
  return testErrors.isEmpty;
}

/// Creates a validator for JSON objects with specific fields.
///
/// The [fieldValidators] parameter maps field names to their validators.
/// If a validator doesn't accept null, the field is considered required.
///
/// The [strictFields] parameter, when set to true, makes the validator
/// fail if the object contains fields not defined in [fieldValidators].
/// Defaults to false.
///
/// For testing, consider using [isJsonObject] helper instead.
///
/// Example:
/// ```dart
/// final userValidator = jsonObject({
///   'name': typeOf<String>(),
///   'age': typeOf<int>(),
///   'email': typeOf<String?>(), // optional
/// });
///
/// // Strict validation - fails if extra fields are present
/// final strictValidator = jsonObject({
///   'name': typeOf<String>(),
/// }, strictFields: true);
/// ```
Validator jsonObject(
  Map<String, Validator> fieldValidators, {
  bool strictFields = false,
}) {
  return (value, path, errors) {
    if (value is! Map) {
      errors.add(
        'Field $path has invalid type '
        '(expected Map, received ${value.runtimeType})',
      );
      return;
    }

    for (final entry in fieldValidators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final fieldPath = _buildFieldPath(path, fieldName);

      if (!value.containsKey(fieldName)) {
        if (!_validatorAcceptsNull(validator)) {
          errors.add('Field $fieldPath is required');
        }
      } else {
        validator(value[fieldName], fieldPath, errors);
      }
    }

    // Check for unexpected fields when strictFields is enabled
    if (strictFields) {
      for (final key in value.keys) {
        if (!fieldValidators.containsKey(key)) {
          final fieldPath = _buildFieldPath(path, key.toString());
          errors.add('Field $fieldPath is not expected');
        }
      }
    }
  };
}

/// Creates a validator for JSON arrays where each item follows a specific schema.
///
/// The [itemFieldValidators] parameter defines the validators for each field
/// of the objects within the array.
///
/// The [strictFields] parameter, when set to true, makes the validator
/// fail if any object in the array contains fields not defined in [itemFieldValidators].
/// Defaults to false.
///
/// For testing, consider using [isJsonArray] helper instead.
///
/// Example:
/// ```dart
/// final usersValidator = jsonArray({
///   'id': typeOf<int>(),
///   'name': typeOf<String>(),
/// });
///
/// // Strict validation - fails if extra fields are present in any object
/// final strictValidator = jsonArray({
///   'id': typeOf<int>(),
/// }, strictFields: true);
/// ```
Validator jsonArray(
  Map<String, Validator> itemFieldValidators, {
  bool strictFields = false,
}) {
  return (value, path, errors) {
    if (value is! List) {
      errors.add(
        'Field $path has invalid type '
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

      for (final entry in itemFieldValidators.entries) {
        final fieldName = entry.key;
        final validator = entry.value;
        final fieldPath = _buildFieldPath(itemPath, fieldName);

        if (!item.containsKey(fieldName)) {
          if (!_validatorAcceptsNull(validator)) {
            errors.add('Field $fieldPath is required');
          }
        } else {
          validator(item[fieldName], fieldPath, errors);
        }
      }

      // Check for unexpected fields when strictFields is enabled
      if (strictFields) {
        for (final key in item.keys) {
          if (!itemFieldValidators.containsKey(key)) {
            final fieldPath = _buildFieldPath(itemPath, key.toString());
            errors.add('Field $fieldPath is not expected');
          }
        }
      }
    }
  };
}

/// Creates a validator for JSON arrays of primitive types.
///
/// Unlike [jsonArray], this validates arrays of primitive values directly,
/// not arrays of objects.
///
/// Supports nullable types - if [T] is nullable (like `String?`),
/// accepts `null` values in the array.
///
/// Example:
/// ```dart
/// final tagsValidator = jsonArrayOf<String>();      // ['tag1', 'tag2']
/// final numbersValidator = jsonArrayOf<int>();      // [1, 2, 3]
/// final nullableValidator = jsonArrayOf<String?>(); // ['text', null, 'more']
/// ```
Validator jsonArrayOf<T>() {
  return (value, path, errors) {
    if (value is! List) {
      errors.add(
        'Field $path has invalid type '
        '(expected List, received ${value.runtimeType})',
      );
      return;
    }

    final isNullable = null is T;

    for (int i = 0; i < value.length; i++) {
      final itemPath = _buildIndexPath(path, i);
      final item = value[i];

      if (item == null && isNullable) {
        continue;
      }

      if (item is! T) {
        final expectedType = T.toString();
        final actualType = item.runtimeType.toString();
        errors.add(
          'Item $itemPath has invalid type '
          '(expected $expectedType, received $actualType)',
        );
      }
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

/// Creates a matcher for JSON objects validation.
///
/// The [strictFields] parameter, when set to true, makes the matcher
/// fail if the object contains fields not defined in [fieldValidators].
/// Defaults to false.
Matcher isJsonObject(
  Map<String, Validator> fieldValidators, {
  bool strictFields = false,
}) =>
    _JsonSchemaMatcher(jsonObject(fieldValidators, strictFields: strictFields));

/// Creates a matcher for JSON arrays of objects validation.
///
/// The [strictFields] parameter, when set to true, makes the matcher
/// fail if any object in the array contains fields not defined in [itemFieldValidators].
/// Defaults to false.
Matcher isJsonArray(
  Map<String, Validator> itemFieldValidators, {
  bool strictFields = false,
}) => _JsonSchemaMatcher(
  jsonArray(itemFieldValidators, strictFields: strictFields),
);

/// Creates a matcher for JSON arrays of primitive types validation.
Matcher isJsonArrayOf<T>() => _JsonSchemaMatcher(jsonArrayOf<T>());
