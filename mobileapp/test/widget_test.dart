import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp/models/user.dart';
import 'package:mobileapp/models/item.dart';
import 'package:mobileapp/models/category.dart';
import 'package:mobileapp/models/message.dart';
import 'package:mobileapp/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator accepts valid emails and rejects invalid ones', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name+tag@sub.domain.co'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('Password validator checks minimum 8 characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('longpassword123'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('Phone validator verifies format', () {
      expect(Validators.phone('+1234567890'), isNull);
      expect(Validators.phone('1234567890'), isNull);
      expect(Validators.phone('abc'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('Confirm password validator verifies matching passwords', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('wrongpassword', 'secret123'), isNotNull);
    });
  });

  group('Model Serialization Tests', () {
    test('UserModel parse JSON and serialize back', () {
      final json = {
        'id': 1,
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'profile_image': 'uploads/profiles/test.jpg',
        'created_at': '2026-08-24 10:00:00',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.fullName, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '+1234567890');
      expect(user.profileImage, 'uploads/profiles/test.jpg');
    });

    test('ItemModel parse JSON and properties', () {
      final json = {
        'id': 10,
        'user_id': 2,
        'category_id': 1,
        'type': 'lost',
        'title': 'Lost Keys',
        'description': 'Keychain with 3 keys found near library',
        'location': 'Library Entrance',
        'date_occurred': '2026-08-24',
        'status': 'active',
        'category_name': 'Keys',
        'poster_name': 'Alice Smith',
      };

      final item = ItemModel.fromJson(json);
      expect(item.id, 10);
      expect(item.isLost, isTrue);
      expect(item.isFound, isFalse);
      expect(item.isActive, isTrue);
      expect(item.title, 'Lost Keys');
      expect(item.categoryName, 'Keys');
      expect(item.posterName, 'Alice Smith');
    });

    test('CategoryModel and MessageModel serialization', () {
      final catJson = {'id': 3, 'name': 'Electronics', 'icon': 'phone_android'};
      final cat = CategoryModel.fromJson(catJson);
      expect(cat.id, 3);
      expect(cat.name, 'Electronics');

      final msgJson = {
        'id': 100,
        'sender_id': 1,
        'receiver_id': 2,
        'item_id': 10,
        'message': 'Hello, I found your keys!',
        'is_read': 0,
        'created_at': '2026-08-24 12:00:00',
      };
      final msg = MessageModel.fromJson(msgJson);
      expect(msg.id, 100);
      expect(msg.isRead, isFalse);
      expect(msg.message, 'Hello, I found your keys!');
    });
  });
}
