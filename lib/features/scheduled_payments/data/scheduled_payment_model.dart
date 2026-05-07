import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledPayment {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String frequency; // 'none', 'weekly', 'monthly', 'yearly'
  final List<int> reminders; // [1, 3, 7]
  final int baseNotificationId; // ID base entero y único para notificaciones
  final bool isPaid; // Estado del pago

  ScheduledPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.frequency,
    required this.reminders,
    required this.baseNotificationId,
    this.isPaid = false,
  });

  factory ScheduledPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledPayment(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      frequency: data['frequency'] ?? 'none',
      reminders: List<int>.from(data['reminders'] ?? []),
      baseNotificationId: data['baseNotificationId'] ?? 0,
      isPaid: data['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'frequency': frequency,
      'reminders': reminders,
      'baseNotificationId': baseNotificationId,
      'isPaid': isPaid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
