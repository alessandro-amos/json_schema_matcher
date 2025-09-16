# JSON Schema Matcher

A Dart library for JSON schema validation using native testing framework matchers.

## Description

JSON Schema Matcher provides a clean and intuitive API for validating complex JSON structures in your Dart tests. Using strongly-typed matchers from the `test` package, you can ensure your JSON data follows the expected schema, with detailed error messages and support for optional fields.

## Features

- ✅ **Type Validation**: Support for primitive and nullable types using `isA<String>()`, `isA<String?>()`
- ✅ **JSON Objects**: Validation of objects with required and optional fields
- ✅ **Arrays**: Support for arrays of objects and primitive types
- ✅ **Strict Validation**: Optional validation of unexpected fields
- ✅ **Detailed Messages**: Specific errors with field paths
- ✅ **Test Integration**: Works natively with Dart's `test` framework matchers

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  json_schema_matcher: ^1.0.0
```

## Basic Usage

### Validating JSON Objects

```dart
import 'package:json_schema_matcher/json_schema_matcher.dart';
import 'package:test/test.dart';

void main() {
  test('user validation', () {
    final userData = {
      'id': 1,
      'name': 'John Silva',
      'email': 'john@email.com',
      'age': 30,
    };

    expect(
      userData,
      isJsonObject({
        'id': isA<int>(),
        'name': isA<String>(),
        'email': isA<String>(),
        'age': isA<int?>(), // optional field
      }),
    );
  });
}
```

### Validating Arrays

```dart
test('posts validation', () {
  final posts = [
    {
      'id': 1,
      'title': 'First Post',
      'content': 'Post content...',
    },
    {
      'id': 2,
      'title': 'Second Post',
      'content': null, // optional content
    },
  ];

  expect(
    posts,
    isJsonArray({
      'id': isA<int>(),
      'title': isA<String>(),
      'content': isA<String?>(), // allows null
    }),
  );
});
```

### Arrays of Primitive Types

```dart
test('tags validation', () {
  final tags = ['dart', 'json', 'validation'];

  expect(tags, isJsonArrayOf(isA<String>()));
});

test('numbers with nulls', () {
  final numbers = [1, 2, null, 4];

  expect(numbers, isJsonArrayOf(isA<int?>())); // allows null
});
```

## API Reference

### Test Matchers

- `isJsonObject(Map<String, Matcher>, {bool strictFields = false})` - Matcher for objects
- `isJsonArray(Map<String, Matcher>, {bool strictFields = false})` - Matcher for arrays of objects
- `isJsonArrayOf(Matcher)` - Matcher for primitive arrays

### Standard Matchers from test package

- `isA<T>()` - Validates if the value is of type T
- `isA<T?>()` - Validates nullable types (can be null or absent)

### Optional Fields

Use nullable type matchers for optional fields:

```dart
// Required field
'name': isA<String>(),

// Optional field (can be null or absent)
'nickname': isA<String?>(),
```

### Strict Field Validation

By default, the library ignores extra fields in JSON objects. Use `strictFields: true` to reject objects with unexpected fields:

```dart
test('strict validation', () {
  final schema = {
    'name': isA<String>(),
    'age': isA<int>(),
  };

  final dataWithExtraField = {
    'name': 'John',
    'age': 30,
    'extraField': 'not allowed',
  };

  // By default, extra fields are ignored
  expect(dataWithExtraField, isJsonObject(schema)); // ✅ passes

  // With strict validation, extra fields cause failure
  expect(
    () => expect(dataWithExtraField, isJsonObject(schema, strictFields: true)),
    throwsA(isA<TestFailure>()), // ❌ fails with "Field [extraField] is not expected"
  );
});
```

This also works for arrays:

```dart
test('strict array validation', () {
  final users = [
    {'id': 1, 'name': 'Alice'},
    {'id': 2, 'name': 'Bob', 'extraField': 'not allowed'},
  ];

  final schema = {'id': isA<int>(), 'name': isA<String>()};

  // Fails because the second object has an extra field
  expect(
    () => expect(users, isJsonArray(schema, strictFields: true)),
    throwsA(isA<TestFailure>()),
  );
});
```

## Error Messages

The library provides clear messages when validation fails:

```
Expected: matches JSON schema
  Actual: {id: abc, name: John}
   Which: does not match JSON schema
- Field [id] has invalid type (expected int, received String)
- Field [email] is required
```

## Complete Example

See the `example/json_schema_matcher_example.dart` file for a complete usage example of the library.

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or pull request in the project repository.