// lib/presentation/thix_weeding/staff/providers/thix_weeding_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thix_weeding_models.dart';
import '../services/thix_weeding_services.dart';

// ================= SERVICES PROVIDERS =================
final weddingServiceProvider = Provider((ref) => WeddingService());
final guestServiceProvider = Provider((ref) => GuestService());
final vendorServiceProvider = Provider((ref) => VendorService());
final budgetServiceProvider = Provider((ref) => BudgetService());
final checklistServiceProvider = Provider((ref) => ChecklistService());
final galleryServiceProvider = Provider((ref) => GalleryService());
final guestbookServiceProvider = Provider((ref) => GuestbookService());
final messageServiceProvider = Provider((ref) => MessageService());
final paymentServiceProvider = Provider((ref) => PaymentService());

// ================= WEDDING =================
final weddingProvider = FutureProvider.family<WeddingModel, String>((ref, weddingId) async {
  return ref.watch(weddingServiceProvider).getById(weddingId);
});

final myWeddingsProvider = FutureProvider.family<List<WeddingModel>, String>((ref, ownerId) async {
  return ref.watch(weddingServiceProvider).getByOwner(ownerId);
});

// ================= GUESTS =================
final guestsProvider = FutureProvider.family<List<GuestModel>, String>((ref, weddingId) async {
  return ref.watch(guestServiceProvider).getByWedding(weddingId);
});

// ================= VENDORS =================
final vendorsProvider = FutureProvider.family<List<VendorModel>, String>((ref, weddingId) async {
  return ref.watch(vendorServiceProvider).getByWedding(weddingId);
});

// ================= BUDGET / EXPENSES =================
final budgetProvider = FutureProvider.family<BudgetModel?, String>((ref, weddingId) async {
  return ref.watch(budgetServiceProvider).getBudget(weddingId);
});

final expensesProvider = FutureProvider.family<List<ExpenseModel>, String>((ref, weddingId) async {
  return ref.watch(budgetServiceProvider).getExpenses(weddingId);
});

// ================= CHECKLIST =================
final checklistProvider = FutureProvider.family<List<ChecklistModel>, String>((ref, weddingId) async {
  return ref.watch(checklistServiceProvider).getByWedding(weddingId);
});

// ================= GALLERY =================
final galleryProvider = FutureProvider.family<List<GalleryModel>, String>((ref, weddingId) async {
  return ref.watch(galleryServiceProvider).getByWedding(weddingId);
});

// ================= GUESTBOOK =================
final guestbookProvider = FutureProvider.family<List<GuestbookModel>, String>((ref, weddingId) async {
  return ref.watch(guestbookServiceProvider).getByWedding(weddingId);
});

// ================= MESSAGES =================
final messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, weddingId) async {
  return ref.watch(messageServiceProvider).getByWedding(weddingId);
});

// ================= PAYMENTS =================
final paymentsProvider = FutureProvider.family<List<PaymentModel>, String>((ref, weddingId) async {
  return ref.watch(paymentServiceProvider).getByWedding(weddingId);
});

final paymentsSummaryProvider = FutureProvider.family<Map<String, double>, String>((ref, weddingId) async {
  final budget = await ref.watch(budgetProvider(weddingId).future);
  final expenses = await ref.watch(expensesProvider(weddingId).future);
  final payments = await ref.watch(paymentsProvider(weddingId).future);
  
  final totalBudget = budget?.totalBudget ?? 0.0;
  
  final totalSpent = expenses.fold<double>(
    0.0, 
    (sum, expense) => sum + expense.amount,
  );
  
  final totalPaid = payments
      .where((payment) => payment.status == 'completed')
      .fold<double>(
        0.0, 
        (sum, payment) => sum + payment.amount,
      );
      
  return {
    'budget': totalBudget,
    'spent': totalSpent,
    'paid': totalPaid,
    'remaining': totalBudget - totalSpent,
  };
});

// ================= DASHBOARD STATS =================
final dashboardStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, weddingId) async {
  final guests = await ref.watch(guestsProvider(weddingId).future);
  final vendors = await ref.watch(vendorsProvider(weddingId).future);
  final tasks = await ref.watch(checklistProvider(weddingId).future);
  
  return {
    'guests': guests.length,
    'present': guests.where((g) => g.isPresent).length,
    'vendors': vendors.length,
    'pendingTasks': tasks.where((t) => !t.isDone).length,
  };
});
