import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scheduled_payment_model.dart';

class ScheduledPaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? 'offline_user';

  CollectionReference get _collection => 
    _db.collection('users').doc(_userId).collection('scheduled_payments');

  // Stream para UI reactiva
  Stream<List<ScheduledPayment>> getPaymentsStream() {
    return _collection.orderBy('dueDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ScheduledPayment.fromFirestore(doc)).toList();
    });
  }

  Future<String> addPayment(ScheduledPayment payment) async {
    final docRef = await _collection.add(payment.toFirestore());
    return docRef.id;
  }

  Future<void> updatePayment(ScheduledPayment payment) async {
    await _collection.doc(payment.id).update(payment.toFirestore());
  }

  Future<void> deletePayment(String paymentId) async {
    await _collection.doc(paymentId).delete();
  }
}
