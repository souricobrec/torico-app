import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPlan {
  final String code;
  final String name;
  final DateTime? updatedAt;

  const UserPlan({required this.code, required this.name, this.updatedAt});

  bool get isBasic => code == 'basic';
  bool get isPlus => code == 'plus';

  factory UserPlan.basic() {
    return const UserPlan(code: 'basic', name: 'TORICO Básico');
  }

  factory UserPlan.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return UserPlan.basic();
    }

    final plan = data['plan'];
    final planName = data['planName'];
    final updatedAt = data['planUpdatedAt'];

    return UserPlan(
      code: plan is String && plan.isNotEmpty ? plan : 'basic',
      name: planName is String && planName.isNotEmpty
          ? planName
          : 'TORICO Básico',
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}

class UserPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _firestore.collection('users').doc(_userId);
  }

  Future<UserPlan> getOrCreateCurrentPlan() async {
    final snapshot = await _userDoc.get();

    if (!snapshot.exists || snapshot.data()?['plan'] == null) {
      await _userDoc.set({
        'plan': 'basic',
        'planName': 'TORICO Básico',
        'planUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return UserPlan.basic();
    }

    return UserPlan.fromMap(snapshot.data());
  }

  Stream<UserPlan> watchCurrentPlan() {
    return _userDoc.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data()?['plan'] == null) {
        await _userDoc.set({
          'plan': 'basic',
          'planName': 'TORICO Básico',
          'planUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return UserPlan.basic();
      }

      return UserPlan.fromMap(snapshot.data());
    });
  }
}
