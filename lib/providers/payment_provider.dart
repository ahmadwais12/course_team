import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/payment.dart';
import 'package:course_emis/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider((ref) => PaymentRepository());

final paymentsNotifierProvider = StreamProvider<List<Payment>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchAll();
});

final paymentsActionsProvider = Provider((ref) {
  return PaymentsActions(ref.watch(paymentRepositoryProvider));
});

class PaymentsActions {
  final PaymentRepository _repository;
  
  PaymentsActions(this._repository);
  
  Future<void> addPayment(Payment payment) async {
    await _repository.create(payment);
  }
  
  Future<void> updatePayment(Payment payment) async {
    await _repository.update(payment);
  }
  
  Future<void> deletePayment(String id) async {
    await _repository.delete(id);
  }
}
