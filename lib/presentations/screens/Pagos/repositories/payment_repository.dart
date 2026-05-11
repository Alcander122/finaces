import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la subcolección de pagos de un usuario específico
  /// Usamos withConverter para que Firestore entienda automáticamente nuestro modelo
  CollectionReference<Payment> _pagosRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pagos')
        .withConverter<Payment>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        data['userId'] = data['userId'] ?? userId;
        return Payment.fromJson(data);
      },
      toFirestore: (payment, _) {
        final json = payment.toJson();
        json.remove('id'); // No guardamos el ID dentro del documento
        return json;
      },
    );
  }

  /// Escucha en tiempo real los pagos del usuario
  Stream<List<Payment>> streamPayments(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _pagosRef(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Crea un nuevo pago
  Future<void> createPayment(Payment payment) async {
    if (payment.userId.isEmpty) throw Exception("User ID requerido");
    await _pagosRef(payment.userId).add(payment);
  }

  /// Actualiza un pago existente
  Future<void> updatePayment(Payment payment) async {
    await _pagosRef(payment.userId).doc(payment.id).update(payment.toJson());
  }

  /// Elimina un pago
  Future<void> deletePayment(String userId, String paymentId) async {
    await _pagosRef(userId).doc(paymentId).delete();
  }
}
