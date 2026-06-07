import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/shared/models/story_model.dart';

void main() {
  group('StoryModel', () {
    test('fromMap creates model with all fields', () {
      final now = DateTime.now();
      final data = {
        'storyId': 'story_abc',
        'ownerId': 'user_123',
        'ownerName': 'Alice',
        'ownerPhotoUrl': 'https://res.cloudinary.com/photo.jpg',
        'imageUrl': 'https://res.cloudinary.com/story.jpg',
        'cloudinaryPublicId': 'betogether/stories/story_abc',
        'caption': 'Beautiful sunset!',
        'viewedBy': ['user_1', 'user_2'],
        'createdAt': now.toIso8601String(),
        'expiresAt': now.add(const Duration(hours: 24)).toIso8601String(),
      };

      final story = StoryModel.fromMap(data);

      expect(story.storyId, 'story_abc');
      expect(story.ownerId, 'user_123');
      expect(story.ownerName, 'Alice');
      expect(story.imageUrl, contains('cloudinary'));
      expect(story.caption, 'Beautiful sunset!');
      expect(story.viewedBy, ['user_1', 'user_2']);
      expect(story.createdAt, isNotNull);
      expect(story.expiresAt, isNotNull);
    });

    test('fromMap handles missing fields', () {
      final story = StoryModel.fromMap({});

      expect(story.storyId, '');
      expect(story.ownerId, '');
      expect(story.ownerName, '');
      expect(story.imageUrl, '');
      expect(story.caption, '');
      expect(story.viewedBy, isEmpty);
      expect(story.createdAt, isNull);
      expect(story.expiresAt, isNull);
    });

    test('fromMap with storyId override', () {
      final story = StoryModel.fromMap(
        {'storyId': 'map_id'},
        storyId: 'override_id',
      );
      expect(story.storyId, 'override_id');
    });

    test('isExpired returns true for expired stories', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(story.isExpired, isTrue);
    });

    test('isExpired returns false for active stories', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(story.isExpired, isFalse);
    });

    test('isExpired returns false when expiresAt is null', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
        expiresAt: null,
      );

      expect(story.isExpired, isFalse);
    });

    test('isViewedBy correctly checks viewer', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'owner',
        imageUrl: 'test.jpg',
        viewedBy: ['user_a', 'user_b'],
      );

      expect(story.isViewedBy('user_a'), isTrue);
      expect(story.isViewedBy('user_b'), isTrue);
      expect(story.isViewedBy('user_c'), isFalse);
    });

    test('isViewedBy returns false for empty viewedBy', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'owner',
        imageUrl: 'test.jpg',
        viewedBy: [],
      );

      expect(story.isViewedBy('anyone'), isFalse);
    });

    test('timeRemaining returns correct duration', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

      final remaining = story.timeRemaining;
      expect(remaining, isNotNull);
      expect(remaining!.inHours, greaterThanOrEqualTo(11));
      expect(remaining.inHours, lessThanOrEqualTo(12));
    });

    test('timeRemaining returns zero for expired stories', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(story.timeRemaining, Duration.zero);
    });

    test('timeRemaining returns null when expiresAt is null', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'user',
        imageUrl: 'test.jpg',
      );

      expect(story.timeRemaining, isNull);
    });

    test('toMap produces correct output', () {
      final story = StoryModel(
        storyId: 'story_1',
        ownerId: 'owner_1',
        ownerName: 'Owner',
        imageUrl: 'https://example.com/img.jpg',
        cloudinaryPublicId: 'stories/story_1',
        caption: 'Test caption',
        viewedBy: ['v1'],
      );

      final map = story.toMap();

      expect(map['storyId'], 'story_1');
      expect(map['ownerId'], 'owner_1');
      expect(map['imageUrl'], 'https://example.com/img.jpg');
      expect(map['caption'], 'Test caption');
      expect(map['viewedBy'], ['v1']);
    });

    test('copyWith creates modified copy', () {
      final story = StoryModel(
        storyId: '1',
        ownerId: 'owner',
        imageUrl: 'original.jpg',
        caption: 'Original',
        viewedBy: ['a'],
      );

      final updated = story.copyWith(
        caption: 'Updated',
        viewedBy: ['a', 'b'],
      );

      expect(updated.storyId, '1'); // unchanged
      expect(updated.caption, 'Updated'); // changed
      expect(updated.viewedBy, ['a', 'b']); // changed
    });

    test('round-trip serialization preserves data', () {
      final now = DateTime.now();
      final original = StoryModel(
        storyId: 'rt_story',
        ownerId: 'rt_owner',
        ownerName: 'RT Owner',
        ownerPhotoUrl: 'rt_photo.jpg',
        imageUrl: 'rt_image.jpg',
        cloudinaryPublicId: 'rt_pub_id',
        caption: 'Round trip test',
        viewedBy: ['v1', 'v2'],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      final map = original.toMap();
      final restored = StoryModel.fromMap(map);

      expect(restored.storyId, original.storyId);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.caption, original.caption);
      expect(restored.viewedBy, original.viewedBy);
    });

    test('toString contains key info', () {
      final story = StoryModel(
        storyId: 'story_1',
        ownerId: 'owner_1',
        imageUrl: 'test.jpg',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final str = story.toString();

      expect(str, contains('story_1'));
      expect(str, contains('owner_1'));
    });
  });
}
