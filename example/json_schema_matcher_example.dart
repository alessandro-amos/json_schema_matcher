import 'package:json_schema_matcher/json_schema_matcher.dart';
import 'package:test/test.dart';

void main() {
  test('user validation', () {
    final userData = {
      'id': 1,
      'name': 'João Silva',
      'email': 'joao@email.com',
      'age': 30,
    };

    expect(
      userData,
      isJsonObject({
        'id': isA<int>(),
        'name': isA<String>(),
        'email': isA<String>(),
        'age': isA<int>(),
      }),
    );
  });

  test('user with optional fields', () {
    final userData = {
      'id': 1,
      'name': 'Maria Santos',
      'email': 'maria@email.com',
    };

    expect(
      userData,
      isJsonObject({
        'id': isA<int>(),
        'name': isA<String>(),
        'email': isA<String>(),
        'phone': isA<String?>(), // optional field
      }),
    );
  });

  test('array of users', () {
    final users = [
      {'id': 1, 'name': 'Alice'},
      {'id': 2, 'name': 'Bob'},
    ];

    expect(
      users,
      isJsonArray({
        'id': isA<int>(),
        'name': isA<String>(),
      }),
    );
  });

  test('array of strings', () {
    expect(
      ['dart', 'json', 'validation'],
      isJsonArrayOf(isA<String>()),
    );
  });

  test('nested object', () {
    final data = {
      'user': {
        'id': 1,
        'name': 'Pedro',
        'profile': {
          'firstName': 'Pedro',
         // 'lastName': 'Costa',
        },
      },
    };

    expect(
      data,
      isJsonObject({
        'user': isJsonObject({
          'id': isA<int>(),
          'name': isA<String>(),
          'profile': isJsonObject({
            'firstName': isA<String>(),
            'lastName': isA<String>(),
          }),
        }),
      }),
    );
  });
}
