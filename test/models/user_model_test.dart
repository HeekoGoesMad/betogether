import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap creates model with all fields', () {
      final data = {
        'uid': 'test_uid_123',
        'username': 'john_doe',
        'displayName': 'John Doe',
        'photoUrl': 'https://res.cloudinary.com/dztravbro/image/upload/avatar.jpg',
        'email': 'john@example.com',
        'friends': ['friend1', 'friend2'],
        'friendCode': 'ABC12345',
        'birthday': '01/15/1995',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-05-27T12:00:00.000Z',
      };

      final user = UserModel.fromMap(data);

      expect(user.uid, 'test_uid_123');
      expect(user.username, 'john_doe');
      expect(user.displayName, 'John Doe');
      expect(user.photoUrl, contains('cloudinary'));
      expect(user.email, 'john@example.com');
      expect(user.friends, ['friend1', 'friend2']);
      expect(user.friendCode, 'ABC12345');
      expect(user.birthday, '01/15/1995');
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('fromMap handles null and missing fields gracefully', () {
      final user = UserModel.fromMap({});

      expect(user.uid, '');
      expect(user.username, '');
      expect(user.displayName, '');
      expect(user.photoUrl, '');
      expect(user.email, '');
      expect(user.friends, isEmpty);
      expect(user.friendCode, '');
      expect(user.birthday, '');
      expect(user.createdAt, isNull);
    });

    test('fromMap with uid override', () {
      final user = UserModel.fromMap(
        {'uid': 'map_uid', 'username': 'test'},
        uid: 'override_uid',
      );
      expect(user.uid, 'override_uid');
    });

    test('toMap produces correct output', () {
      final user = UserModel(
        uid: 'uid1',
        username: 'alice',
        displayName: 'Alice',
        photoUrl: 'https://example.com/photo.jpg',
        email: 'alice@test.com',
        friends: ['bob'],
        friendCode: 'XYZW',
        birthday: '03/20/2000',
      );

      final map = user.toMap();

      expect(map['uid'], 'uid1');
      expect(map['username'], 'alice');
      expect(map['displayName'], 'Alice');
      expect(map['friends'], ['bob']);
      expect(map['friendCode'], 'XYZW');
    });

    test('copyWith creates new instance with overridden fields', () {
      final user = UserModel(
        uid: 'uid1',
        username: 'original',
        displayName: 'Original',
        friends: ['a', 'b'],
      );

      final updated = user.copyWith(
        displayName: 'Updated',
        friends: ['a', 'b', 'c'],
      );

      expect(updated.uid, 'uid1'); // unchanged
      expect(updated.username, 'original'); // unchanged
      expect(updated.displayName, 'Updated'); // changed
      expect(updated.friends, ['a', 'b', 'c']); // changed
    });

    test('copyWith preserves all fields when no overrides', () {
      final user = UserModel(
        uid: 'uid1',
        username: 'test',
        displayName: 'Test User',
        photoUrl: 'photo.jpg',
        email: 'test@test.com',
        friends: ['x'],
        friendCode: 'CODE',
        birthday: '01/01/2000',
      );

      final copy = user.copyWith();

      expect(copy.uid, user.uid);
      expect(copy.username, user.username);
      expect(copy.displayName, user.displayName);
      expect(copy.photoUrl, user.photoUrl);
      expect(copy.friends, user.friends);
    });

    test('isFriendsWith returns correct result', () {
      final user = UserModel(
        uid: 'me',
        username: 'me',
        displayName: 'Me',
        friends: ['friend1', 'friend2'],
      );

      expect(user.isFriendsWith('friend1'), isTrue);
      expect(user.isFriendsWith('friend2'), isTrue);
      expect(user.isFriendsWith('stranger'), isFalse);
    });

    test('isFriendsWith returns false for empty friends list', () {
      final user = UserModel(
        uid: 'me',
        username: 'me',
        displayName: 'Me',
        friends: [],
      );

      expect(user.isFriendsWith('anyone'), isFalse);
    });

    test('equality is based on uid', () {
      final user1 = UserModel(uid: 'same', username: 'a', displayName: 'A');
      final user2 = UserModel(uid: 'same', username: 'b', displayName: 'B');
      final user3 = UserModel(uid: 'diff', username: 'a', displayName: 'A');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('hashCode is consistent with equality', () {
      final user1 = UserModel(uid: 'same', username: 'a', displayName: 'A');
      final user2 = UserModel(uid: 'same', username: 'b', displayName: 'B');

      expect(user1.hashCode, user2.hashCode);
    });

    test('toString contains uid and username', () {
      final user = UserModel(uid: 'uid1', username: 'test', displayName: 'T');
      final str = user.toString();

      expect(str, contains('uid1'));
      expect(str, contains('test'));
    });

    test('round-trip serialization preserves data', () {
      final original = UserModel(
        uid: 'roundtrip',
        username: 'rt_user',
        displayName: 'Round Trip',
        photoUrl: 'https://example.com/photo.jpg',
        email: 'rt@test.com',
        friends: ['f1', 'f2', 'f3'],
        friendCode: 'RTCODE',
        birthday: '06/15/1990',
      );

      final map = original.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.uid, original.uid);
      expect(restored.username, original.username);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.email, original.email);
      expect(restored.friends, original.friends);
      expect(restored.friendCode, original.friendCode);
      expect(restored.birthday, original.birthday);
    });
  });
}
