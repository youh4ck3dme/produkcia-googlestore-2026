import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(FirebaseFirestore.instance);
});

class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository(this._firestore);

  Stream<UserSettingsModel> watchSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserSettingsModel.empty();
      }
      return UserSettingsModel.fromMap(snapshot.data()!);
    });
  }

  Future<UserSettingsModel> getSettings(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default')
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return UserSettingsModel.empty();
    }
    return UserSettingsModel.fromMap(snapshot.data()!);
  }

  Future<void> updateSettings(String userId, UserSettingsModel settings) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('default')
        .set(settings.toMap());
  }
}
