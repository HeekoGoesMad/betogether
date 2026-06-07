import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/shared/models/friend_request_model.dart';

void main() {
  group('FriendRequestModel', () {
    test('fromMap creates model with all fields', () {
      final data = {
        'id': 'req_123',
        'fromUid': 'user_a',
        'toUid': 'user_b',
        'fromName': 'Alice',
        'fromPhotoUrl': 'https://example.com/alice.jpg',
        'toName': 'Bob',
        'toPhotoUrl': 'https://example.com/bob.jpg',
        'status': 'pending',
        'createdAt': '2026-05-27T12:00:00.000Z',
      };

      final request = FriendRequestModel.fromMap(data);

      expect(request.fromUid, 'user_a');
      expect(request.toUid, 'user_b');
      expect(request.fromName, 'Alice');
      expect(request.toName, 'Bob');
      expect(request.status, FriendRequestStatus.pending);
      expect(request.createdAt, isNotNull);
    });

    test('fromMap with id override', () {
      final request = FriendRequestModel.fromMap(
        {'id': 'map_id', 'fromUid': 'a', 'toUid': 'b'},
        id: 'override_id',
      );
      expect(request.id, 'override_id');
    });

    test('fromMap handles missing fields', () {
      final request = FriendRequestModel.fromMap({});

      expect(request.id, '');
      expect(request.fromUid, '');
      expect(request.toUid, '');
      expect(request.fromName, '');
      expect(request.status, FriendRequestStatus.pending);
    });

    test('status parsing handles all values', () {
      expect(
        FriendRequestModel.fromMap({'status': 'pending'}).status,
        FriendRequestStatus.pending,
      );
      expect(
        FriendRequestModel.fromMap({'status': 'accepted'}).status,
        FriendRequestStatus.accepted,
      );
      expect(
        FriendRequestModel.fromMap({'status': 'rejected'}).status,
        FriendRequestStatus.rejected,
      );
    });

    test('status parsing defaults to pending for unknown values', () {
      expect(
        FriendRequestModel.fromMap({'status': 'unknown'}).status,
        FriendRequestStatus.pending,
      );
      expect(
        FriendRequestModel.fromMap({'status': null}).status,
        FriendRequestStatus.pending,
      );
    });

    test('isPending returns correct result', () {
      final pending = FriendRequestModel(
        id: '1', fromUid: 'a', toUid: 'b',
        status: FriendRequestStatus.pending,
      );
      final accepted = FriendRequestModel(
        id: '2', fromUid: 'a', toUid: 'b',
        status: FriendRequestStatus.accepted,
      );

      expect(pending.isPending, isTrue);
      expect(pending.isAccepted, isFalse);
      expect(pending.isRejected, isFalse);
      expect(accepted.isPending, isFalse);
      expect(accepted.isAccepted, isTrue);
    });

    test('isRejected returns correct result', () {
      final rejected = FriendRequestModel(
        id: '1', fromUid: 'a', toUid: 'b',
        status: FriendRequestStatus.rejected,
      );

      expect(rejected.isRejected, isTrue);
      expect(rejected.isPending, isFalse);
      expect(rejected.isAccepted, isFalse);
    });

    test('toMap produces correct output', () {
      final request = FriendRequestModel(
        id: 'req_1',
        fromUid: 'user_x',
        toUid: 'user_y',
        fromName: 'UserX',
        fromPhotoUrl: 'photo_x.jpg',
        toName: 'UserY',
        toPhotoUrl: 'photo_y.jpg',
        status: FriendRequestStatus.accepted,
      );

      final map = request.toMap();

      expect(map['id'], 'req_1');
      expect(map['fromUid'], 'user_x');
      expect(map['toUid'], 'user_y');
      expect(map['status'], 'accepted');
    });

    test('round-trip serialization preserves data', () {
      final original = FriendRequestModel(
        id: 'rt_req',
        fromUid: 'from_user',
        toUid: 'to_user',
        fromName: 'From',
        fromPhotoUrl: 'from.jpg',
        toName: 'To',
        toPhotoUrl: 'to.jpg',
        status: FriendRequestStatus.pending,
      );

      final map = original.toMap();
      final restored = FriendRequestModel.fromMap(map, id: original.id);

      expect(restored.id, original.id);
      expect(restored.fromUid, original.fromUid);
      expect(restored.toUid, original.toUid);
      expect(restored.status, original.status);
    });

    test('toString contains key info', () {
      final request = FriendRequestModel(
        id: 'req_1', fromUid: 'a', toUid: 'b',
        status: FriendRequestStatus.pending,
      );
      final str = request.toString();

      expect(str, contains('req_1'));
      expect(str, contains('pending'));
    });
  });

  group('FriendRequestStatus', () {
    test('enum has correct values', () {
      expect(FriendRequestStatus.values.length, 3);
      expect(FriendRequestStatus.pending.name, 'pending');
      expect(FriendRequestStatus.accepted.name, 'accepted');
      expect(FriendRequestStatus.rejected.name, 'rejected');
    });
  });
}
