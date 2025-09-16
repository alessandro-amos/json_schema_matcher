import 'package:json_schema_matcher/json_schema_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Schema Matcher Tests', () {
    // Testes existentes
    test('should validate simple object', () {
      final schema = {'name': typeOf<String>(), 'age': typeOf<int>()};

      final validData = {'name': 'João', 'age': 30};

      expect(validData, isJsonObject(schema));
    });

    test('should fail with missing field', () {
      final schema = {'name': typeOf<String>(), 'age': typeOf<int>()};

      final invalidData = {
        'name': 'João',
        // age is missing
      };

      expect(
        () => expect(invalidData, isJsonObject(schema)),
        throwsA(isA<TestFailure>()),
      );
    });

    test('should validate nullable fields', () {
      final schema = {
        'name': typeOf<String>(),
        'email': typeOf<String?>(), // nullable
        'age': typeOf<int?>(), // nullable
      };

      // Test with missing nullable fields
      expect({
        'name': 'Maria',
        // email and age are missing but nullable
      }, isJsonObject(schema));

      // Test with null values
      expect({'name': 'Ana', 'email': null, 'age': null}, isJsonObject(schema));

      // Test with actual values
      expect({
        'name': 'Pedro',
        'email': 'pedro@email.com',
        'age': 25,
      }, isJsonObject(schema));
    });

    test('should validate arrays', () {
      final schema = {
        'users': jsonArray({
          'name': typeOf<String>(),
          'email': typeOf<String?>(),
        }),
      };

      final validData = {
        'users': [
          {'name': 'User 1', 'email': 'user1@email.com'},
          {
            'name': 'User 2',
            // email is missing but nullable
          },
          {'name': 'User 3', 'email': null},
        ],
      };

      expect(validData, isJsonObject(schema));
    });

    test('should fail with wrong type', () {
      final schema = {'name': typeOf<String>(), 'age': typeOf<int>()};

      final invalidData = {
        'name': 'João',
        'age': 'thirty', // should be int
      };

      expect(
        () => expect(invalidData, isJsonObject(schema)),
        throwsA(isA<TestFailure>()),
      );
    });

    test('should provide detailed error messages', () {
      final invalidData = {
        'name': 'User',
        'posts': [
          {
            'title': 'Post 1',
            // id is missing
          },
          {
            'id': '2', // should be int
            'title': 'Post 2',
          },
        ],
      };

      try {
        expect(
          invalidData,
          isJsonObject({
            'name': typeOf<String>(),
            'posts': jsonArray({
              'id': typeOf<int>(),
              'title': typeOf<String>(),
            }),
          }),
        );
        fail('Should have thrown TestFailure');
      } catch (e) {
        expect(e.toString(), contains('Field [posts][0][id] is required'));
        expect(e.toString(), contains('Field [posts][1][id] has invalid type'));
      }
    });

    test('should validate empty array', () {
      final schema = {
        'items': jsonArray({'id': typeOf<int>(), 'name': typeOf<String>()}),
      };

      final validData = {'items': []};

      expect(validData, isJsonObject(schema));
    });

    test('should fail when array contains wrong type', () {
      final schema = {
        'numbers': jsonArray({'value': typeOf<int>()}),
      };

      final invalidData = {
        'numbers': [
          {'value': 1},
          {'value': 'not a number'}, // should be int
          {'value': 3},
        ],
      };

      expect(
        () => expect(invalidData, isJsonObject(schema)),
        throwsA(isA<TestFailure>()),
      );
    });

    test('should handle nested objects', () {
      final schema = {
        'user': jsonObject({
          'id': typeOf<int>(),
          'profile': jsonObject({
            'firstName': typeOf<String>(),
            'lastName': typeOf<String>(),
            'bio': typeOf<String?>(),
          }),
        }),
      };

      final validData = {
        'user': {
          'id': 1,
          'profile': {'firstName': 'John', 'lastName': 'Doe', 'bio': null},
        },
      };

      expect(validData, isJsonObject(schema));
    });

    test('should fail with non-map data for object validation', () {
      final schema = {'name': typeOf<String>()};

      expect(
        () => expect('not an object', isJsonObject(schema)),
        throwsA(isA<TestFailure>()),
      );
    });

    test('should fail with non-list data for array validation', () {
      final schema = {'id': typeOf<int>()};

      expect(
        () => expect('not an array', isJsonArray(schema)),
        throwsA(isA<TestFailure>()),
      );
    });

    // Novos testes para jsonArrayOf
    group('jsonArrayOf Tests', () {
      test('should validate array of strings', () {
        final data = ['apple', 'banana', 'cherry'];
        expect(data, isJsonArrayOf<String>());
      });

      test('should validate array of integers', () {
        final data = [1, 2, 3, 42, 100];
        expect(data, isJsonArrayOf<int>());
      });

      test('should validate array of booleans', () {
        final data = [true, false, true, true];
        expect(data, isJsonArrayOf<bool>());
      });

      test('should validate array of doubles', () {
        final data = [1.5, 2.7, 3.14, 42.0];
        expect(data, isJsonArrayOf<double>());
      });

      test('should validate empty array of primitives', () {
        final data = <String>[];
        expect(data, isJsonArrayOf<String>());
      });

      test('should validate nullable array of strings', () {
        final data = ['hello', null, 'world', null];
        expect(data, isJsonArrayOf<String?>());
      });

      test('should validate nullable array of integers', () {
        final data = [1, null, 3, null, 5];
        expect(data, isJsonArrayOf<int?>());
      });

      test('should fail with mixed types in string array', () {
        final data = ['hello', 42, 'world'];
        expect(
          () => expect(data, isJsonArrayOf<String>()),
          throwsA(isA<TestFailure>()),
        );
      });

      test('should fail with null in non-nullable array', () {
        final data = ['hello', null, 'world'];
        expect(
          () => expect(data, isJsonArrayOf<String>()),
          throwsA(isA<TestFailure>()),
        );
      });

      test('should fail when validating non-list with jsonArrayOf', () {
        expect(
          () => expect('not a list', isJsonArrayOf<String>()),
          throwsA(isA<TestFailure>()),
        );
      });

      test('should provide detailed error for invalid array item type', () {
        final data = [1, 2, 'not a number', 4];
        try {
          expect(data, isJsonArrayOf<int>());
          fail('Should have thrown TestFailure');
        } catch (e) {
          expect(e.toString(), contains('[2] has invalid type'));
          expect(e.toString(), contains('expected int'));
          expect(e.toString(), contains('received String'));
        }
      });
    });

    // Testes para objetos com arrays de primitivos
    group('Objects with Primitive Arrays', () {
      test('should validate object with string array', () {
        final schema = {
          'name': typeOf<String>(),
          'tags': jsonArrayOf<String>(),
        };

        final data = {
          'name': 'Product',
          'tags': ['electronics', 'mobile', 'smartphone'],
        };

        expect(data, isJsonObject(schema));
      });

      test('should validate object with nullable primitive array', () {
        final schema = {
          'id': typeOf<int>(),
          'scores': jsonArrayOf<double?>(),
        };

        final data = {
          'id': 1,
          'scores': [85.5, null, 92.0, null, 78.3],
        };

        expect(data, isJsonObject(schema));
      });

      test('should validate object with multiple primitive arrays', () {
        final schema = {
          'name': typeOf<String>(),
          'numbers': jsonArrayOf<int>(),
          'flags': jsonArrayOf<bool>(),
          'scores': jsonArrayOf<double>(),
        };

        final data = {
          'name': 'Test',
          'numbers': [1, 2, 3],
          'flags': [true, false, true],
          'scores': [1.5, 2.7, 3.9],
        };

        expect(data, isJsonObject(schema));
      });
    });

    // Testes para diferentes tipos primitivos
    group('Type Validation Tests', () {
      test('should validate different primitive types', () {
        final schema = {
          'stringField': typeOf<String>(),
          'intField': typeOf<int>(),
          'doubleField': typeOf<double>(),
          'boolField': typeOf<bool>(),
          'dynamicField': typeOf<dynamic>(),
        };

        final data = {
          'stringField': 'hello',
          'intField': 42,
          'doubleField': 3.14,
          'boolField': true,
          'dynamicField': 'anything',
        };

        expect(data, isJsonObject(schema));
      });

      test('should accept any type for dynamic field', () {
        final schema = {'field': typeOf<dynamic>()};

        expect({'field': 'string'}, isJsonObject(schema));
        expect({'field': 42}, isJsonObject(schema));
        expect({'field': true}, isJsonObject(schema));
        expect({
          'field': [1, 2, 3],
        }, isJsonObject(schema));
        expect({
          'field': {'nested': 'object'},
        }, isJsonObject(schema));
        expect({'field': null}, isJsonObject(schema));
      });

      test('should validate nums as both int and double', () {
        final intData = {'value': 42};
        final doubleData = {'value': 42.0};

        expect(intData, isJsonObject({'value': typeOf<num>()}));
        expect(doubleData, isJsonObject({'value': typeOf<num>()}));
      });
    });

    // Testes para aninhamento complexo
    group('Complex Nesting Tests', () {
      test('should validate deeply nested objects', () {
        final schema = {
          'level1': jsonObject({
            'level2': jsonObject({
              'level3': jsonObject({
                'value': typeOf<String>(),
              }),
            }),
          }),
        };

        final data = {
          'level1': {
            'level2': {
              'level3': {'value': 'deep'},
            },
          },
        };

        expect(data, isJsonObject(schema));
      });

      test('should validate array of objects with nested arrays', () {
        final schema = {
          'users': jsonArray({
            'id': typeOf<int>(),
            'name': typeOf<String>(),
            'tags': jsonArrayOf<String>(),
            'scores': jsonArrayOf<double?>(),
          }),
        };

        final data = {
          'users': [
            {
              'id': 1,
              'name': 'Alice',
              'tags': ['admin', 'active'],
              'scores': [95.5, 88.0, null],
            },
            {
              'id': 2,
              'name': 'Bob',
              'tags': ['user'],
              'scores': [75.5, null, 82.3],
            },
          ],
        };

        expect(data, isJsonObject(schema));
      });

      test('should validate object with mixed array types', () {
        final schema = {
          'metadata': jsonObject({
            'stringList': jsonArrayOf<String>(),
            'intList': jsonArrayOf<int>(),
            'objectList': jsonArray({
              'id': typeOf<int>(),
              'active': typeOf<bool>(),
            }),
          }),
        };

        final data = {
          'metadata': {
            'stringList': ['a', 'b', 'c'],
            'intList': [1, 2, 3],
            'objectList': [
              {'id': 1, 'active': true},
              {'id': 2, 'active': false},
            ],
          },
        };

        expect(data, isJsonObject(schema));
      });
    });

    // Testes para cenários de erro detalhados
    group('Detailed Error Reporting Tests', () {
      test('should report nested object field errors', () {
        final schema = {
          'user': jsonObject({
            'profile': jsonObject({
              'name': typeOf<String>(),
              'age': typeOf<int>(),
            }),
          }),
        };

        final invalidData = {
          'user': {
            'profile': {
              'name': 'John',
              'age': 'not a number', // should be int
            },
          },
        };

        try {
          expect(invalidData, isJsonObject(schema));
          fail('Should have thrown TestFailure');
        } catch (e) {
          expect(
            e.toString(),
            contains('[user][profile][age] has invalid type'),
          );
        }
      });

      test('should report array of primitives errors with correct path', () {
        final schema = {
          'numbers': jsonArrayOf<int>(),
        };

        final invalidData = {
          'numbers': [1, 2, 'not a number', 4, 'another string'],
        };

        try {
          expect(invalidData, isJsonObject(schema));
          fail('Should have thrown TestFailure');
        } catch (e) {
          expect(e.toString(), contains('[numbers][2] has invalid type'));
          expect(e.toString(), contains('[numbers][4] has invalid type'));
        }
      });

      test('should report multiple errors in nested structure', () {
        final schema = {
          'data': jsonArray({
            'id': typeOf<int>(),
            'details': jsonObject({
              'name': typeOf<String>(),
              'value': typeOf<double>(),
            }),
          }),
        };

        final invalidData = {
          'data': [
            {
              'id': 'not an int', // error 1
              'details': {
                'name': 123, // error 2
                'value': 'not a double', // error 3
              },
            },
            {
              'id': 2,
              'details': {
                'name': 'valid',
                // value is missing - error 4
              },
            },
          ],
        };

        try {
          expect(invalidData, isJsonObject(schema));
          fail('Should have thrown TestFailure');
        } catch (e) {
          final errorString = e.toString();
          expect(errorString, contains('[data][0][id] has invalid type'));
          expect(
            errorString,
            contains('[data][0][details][name] has invalid type'),
          );
          expect(
            errorString,
            contains('[data][0][details][value] has invalid type'),
          );
          expect(
            errorString,
            contains('[data][1][details][value] is required'),
          );
        }
      });
    });

    // Testes para edge cases
    group('Edge Cases', () {
      test('should handle empty objects', () {
        final schema = <String, Validator>{};
        final data = <String, dynamic>{};
        expect(data, isJsonObject(schema));
      });

      test('should ignore extra fields in objects by default', () {
        final schema = {'name': typeOf<String>()};
        final data = {
          'name': 'John',
          'extraField': 'should be ignored',
          'anotherExtra': 42,
        };
        expect(data, isJsonObject(schema));
      });

      test('should handle null as root value for nullable type check', () {
        final errors = <String>[];
        typeOf<String?>()(null, 'test', errors);
        expect(errors, isEmpty);

        typeOf<String>()(null, 'test', errors);
        expect(errors, isNotEmpty);
      });

      test('should validate array containing only nulls for nullable type', () {
        final data = [null, null, null];
        expect(data, isJsonArrayOf<String?>());
      });

      test('should handle very large arrays', () {
        final data = List.generate(1000, (i) => i);
        expect(data, isJsonArrayOf<int>());
      });

      test('should handle objects with many fields', () {
        final schema = <String, Validator>{};
        final data = <String, dynamic>{};

        for (int i = 0; i < 100; i++) {
          schema['field$i'] = typeOf<int>();
          data['field$i'] = i;
        }

        expect(data, isJsonObject(schema));
      });
    });

    // Testes para validação de matcher behavior
    group('Matcher Behavior Tests', () {
      test('matcher should describe itself correctly', () {
        final matcher = isJsonObject({'name': typeOf<String>()});
        final description = matcher.describe(StringDescription());
        expect(description.toString(), contains('matches JSON schema'));
      });

      test('matcher should provide mismatch description', () {
        final matcher = isJsonObject({'name': typeOf<String>()});
        final invalidData = {'name': 123};

        final matchState = <String, dynamic>{};
        final matches = matcher.matches(invalidData, matchState);

        expect(matches, isFalse);
        expect(matchState['errors'], isNotNull);

        final mismatchDescription = StringDescription();
        matcher.describeMismatch(
          invalidData,
          mismatchDescription,
          matchState,
          false,
        );

        expect(
          mismatchDescription.toString(),
          contains('does not match JSON schema'),
        );
        expect(
          mismatchDescription.toString(),
          contains('[name] has invalid type'),
        );
      });
    });

    // Testes específicos para tipos do Dart
    group('Dart Type System Tests', () {
      test('should work with List<dynamic>', () {
        final schema = {'items': typeOf<List>()};
        final data = {
          'items': [
            1,
            'string',
            true,
            {'nested': 'object'},
          ],
        };
        expect(data, isJsonObject(schema));
      });

      test('should work with Map<String, dynamic>', () {
        final schema = {'config': typeOf<Map>()};
        final data = {
          'config': {'key1': 'value1', 'key2': 42},
        };
        expect(data, isJsonObject(schema));
      });

      test('should differentiate between num, int, and double', () {
        final intValue = 42;
        final doubleValue = 42.5;

        // int should work for num
        expect({'value': intValue}, isJsonObject({'value': typeOf<num>()}));
        // double should work for num
        expect({'value': doubleValue}, isJsonObject({'value': typeOf<num>()}));

        // int should work for int
        expect({'value': intValue}, isJsonObject({'value': typeOf<int>()}));
        // int should NOT work for double (in Dart, 42 is int, not double)
        expect(
          () => expect({
            'value': intValue,
          }, isJsonObject({'value': typeOf<double>()})),
          throwsA(isA<TestFailure>()),
        );
      });
    });

    // Testes para strictFields feature
    group('StrictFields Feature Tests', () {
      test('should reject extra fields in objects when strictFields is true', () {
        final schema = {'name': typeOf<String>()};
        final data = {
          'name': 'John',
          'extraField': 'should cause error',
          'anotherExtra': 42,
        };

        expect(
          () => expect(data, isJsonObject(schema, strictFields: true)),
          throwsA(isA<TestFailure>()),
        );
      });

      test('should accept exact schema match when strictFields is true', () {
        final schema = {
          'name': typeOf<String>(),
          'age': typeOf<int>(),
        };
        final data = {
          'name': 'John',
          'age': 30,
        };

        expect(data, isJsonObject(schema, strictFields: true));
      });

      test('should provide detailed error for unexpected fields', () {
        final schema = {'name': typeOf<String>()};
        final data = {
          'name': 'John',
          'unexpected': 'field',
          'another': 123,
        };

        try {
          expect(data, isJsonObject(schema, strictFields: true));
          fail('Should have thrown TestFailure');
        } catch (e) {
          expect(e.toString(), contains('[unexpected] is not expected'));
          expect(e.toString(), contains('[another] is not expected'));
        }
      });

      test('should reject extra fields in array objects when strictFields is true', () {
        final schema = {
          'users': jsonArray({
            'id': typeOf<int>(),
            'name': typeOf<String>(),
          }),
        };
        final data = {
          'users': [
            {
              'id': 1,
              'name': 'Alice',
              'extraField': 'not allowed',
            },
            {
              'id': 2,
              'name': 'Bob',
            },
          ],
        };

        expect(
          () => expect(data, isJsonObject(schema)),
          isNot(throwsA(isA<TestFailure>())),
        );

        expect(
          () => expect(data, isJsonArray({'id': typeOf<int>(), 'name': typeOf<String>()}, strictFields: true)),
          throwsA(isA<TestFailure>()),
        );
      });

      test('should accept exact array schema match when strictFields is true', () {
        final data = [
          {
            'id': 1,
            'name': 'Alice',
          },
          {
            'id': 2,
            'name': 'Bob',
          },
        ];

        expect(data, isJsonArray({
          'id': typeOf<int>(),
          'name': typeOf<String>(),
        }, strictFields: true));
      });

      test('should provide detailed error for unexpected fields in arrays', () {
        final data = [
          {
            'id': 1,
            'name': 'Alice',
            'unexpected': 'field',
          },
          {
            'id': 2,
            'name': 'Bob',
            'another': 123,
          },
        ];

        try {
          expect(data, isJsonArray({
            'id': typeOf<int>(),
            'name': typeOf<String>(),
          }, strictFields: true));
          fail('Should have thrown TestFailure');
        } catch (e) {
          expect(e.toString(), contains('[0][unexpected] is not expected'));
          expect(e.toString(), contains('[1][another] is not expected'));
        }
      });

      test('should work with nested strict validation', () {
        final schema = {
          'user': jsonObject({
            'id': typeOf<int>(),
            'profile': jsonObject({
              'name': typeOf<String>(),
              'age': typeOf<int>(),
            }, strictFields: true),
          }, strictFields: true),
        };

        final validData = {
          'user': {
            'id': 1,
            'profile': {
              'name': 'John',
              'age': 30,
            },
          },
        };

        final invalidData = {
          'user': {
            'id': 1,
            'profile': {
              'name': 'John',
              'age': 30,
              'extraField': 'not allowed',
            },
          },
        };

        expect(validData, isJsonObject(schema));
        expect(
          () => expect(invalidData, isJsonObject(schema)),
          throwsA(isA<TestFailure>()),
        );
      });

      test('strictFields should work with nullable fields', () {
        final schema = {
          'name': typeOf<String>(),
          'email': typeOf<String?>(),
        };

        final validData = {
          'name': 'John',
          'email': null,
        };

        final invalidData = {
          'name': 'John',
          'email': null,
          'extra': 'field',
        };

        expect(validData, isJsonObject(schema, strictFields: true));
        expect(
          () => expect(invalidData, isJsonObject(schema, strictFields: true)),
          throwsA(isA<TestFailure>()),
        );
      });
    });
  });
}
