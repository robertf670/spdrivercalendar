import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

void main() {
  setUp(() async {
    // Initialize with mock preferences
    SharedPreferences.setMockInitialValues({});
    // Clear any existing cache
    await StorageService.clear();
  });

  group('StorageService Tests', () {
    test('getBool returns default value when key not found', () async {
      // Arrange
      const testKey = 'non_existent_key';
      const defaultValue = true;
      
      // Act
      final result = await StorageService.getBool(testKey, defaultValue: defaultValue);
      
      // Assert
      expect(result, defaultValue);
    });

    test('saveBool stores value correctly', () async {
      // Arrange
      const testKey = 'test_key';
      const testValue = true;
      
      // Act
      await StorageService.saveBool(testKey, testValue);
      
      // Assert
      final result = await StorageService.getBool(testKey);
      expect(result, testValue);
    });

    test('getString returns null when key not found', () async {
      // Arrange
      const testKey = 'non_existent_key';
      
      // Act
      final result = await StorageService.getString(testKey);
      
      // Assert
      expect(result, null);
    });

    test('saveString stores value correctly', () async {
      // Arrange
      const testKey = 'test_key';
      const testValue = 'test_value';
      
      // Act
      await StorageService.saveString(testKey, testValue);
      
      // Assert
      final result = await StorageService.getString(testKey);
      expect(result, testValue);
    });

    test('clear removes all data', () async {
      // Arrange
      const testKey = 'test_key';
      const testValue = 'test_value';
      await StorageService.saveString(testKey, testValue);
      
      // Act
      await StorageService.clear();
      
      // Assert
      final result = await StorageService.getString(testKey);
      expect(result, null);
    });
  });
} 