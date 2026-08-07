import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';

/// Local persistence layer using SharedPreferences (JSON-encoded collections).
///
/// The method names and shapes mirror what a real Firestore-backed service
/// would look like, so this can be swapped for `cloud_firestore` calls later
/// without touching any screen code.
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------------- Users ----------------

  Future<List<UserModel>> getUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(AppConstants.prefsUsersKey) ?? [];
    return raw.map((s) => UserModel.fromMap(jsonDecode(s))).toList();
  }

  Future<void> saveUser(UserModel user) async {
    final users = await getUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      users[idx] = user;
    } else {
      users.add(user);
    }
    await _writeUsers(users);
  }

  Future<void> deleteUser(String id) async {
    final users = await getUsers();
    users.removeWhere((u) => u.id == id);
    await _writeUsers(users);
  }

  Future<void> _writeUsers(List<UserModel> users) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      AppConstants.prefsUsersKey,
      users.map((u) => jsonEncode(u.toMap())).toList(),
    );
  }

  // ---------------- Customers ----------------

  Future<List<CustomerModel>> getCustomers() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(AppConstants.prefsCustomersKey) ?? [];
    return raw.map((s) => CustomerModel.fromMap(jsonDecode(s))).toList();
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final customers = await getCustomers();
    final idx = customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      customers[idx] = customer;
    } else {
      customers.add(customer);
    }
    await _writeCustomers(customers);
  }

  Future<void> deleteCustomer(String id) async {
    final customers = await getCustomers();
    customers.removeWhere((c) => c.id == id);
    await _writeCustomers(customers);
  }

  Future<void> _writeCustomers(List<CustomerModel> customers) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      AppConstants.prefsCustomersKey,
      customers.map((c) => jsonEncode(c.toMap())).toList(),
    );
  }

  // ---------------- Invoices ----------------

  Future<List<InvoiceModel>> getInvoices() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(AppConstants.prefsInvoicesKey) ?? [];
    return raw.map((s) => InvoiceModel.fromMap(jsonDecode(s))).toList();
  }

  Future<void> saveInvoice(InvoiceModel invoice) async {
    final invoices = await getInvoices();
    final idx = invoices.indexWhere((i) => i.id == invoice.id);
    if (idx >= 0) {
      invoices[idx] = invoice;
    } else {
      invoices.add(invoice);
    }
    await _writeInvoices(invoices);
  }

  Future<void> deleteInvoice(String id) async {
    final invoices = await getInvoices();
    invoices.removeWhere((i) => i.id == id);
    await _writeInvoices(invoices);
  }

  Future<void> _writeInvoices(List<InvoiceModel> invoices) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      AppConstants.prefsInvoicesKey,
      invoices.map((i) => jsonEncode(i.toMap())).toList(),
    );
  }

  Future<int> nextInvoiceNumber() async {
    final prefs = await _prefs;
    final current = prefs.getInt(AppConstants.prefsInvoiceCounterKey) ?? 1000;
    final next = current + 1;
    await prefs.setInt(AppConstants.prefsInvoiceCounterKey, next);
    return next;
  }

  // ---------------- Payments ----------------

  Future<List<PaymentModel>> getPayments() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(AppConstants.prefsPaymentsKey) ?? [];
    return raw.map((s) => PaymentModel.fromMap(jsonDecode(s))).toList();
  }

  Future<void> savePayment(PaymentModel payment) async {
    final payments = await getPayments();
    final idx = payments.indexWhere((p) => p.id == payment.id);
    if (idx >= 0) {
      payments[idx] = payment;
    } else {
      payments.add(payment);
    }
    final prefs = await _prefs;
    await prefs.setStringList(
      AppConstants.prefsPaymentsKey,
      payments.map((p) => jsonEncode(p.toMap())).toList(),
    );
  }

  Future<List<PaymentModel>> getPaymentsForInvoice(String invoiceId) async {
    final payments = await getPayments();
    return payments.where((p) => p.invoiceId == invoiceId).toList();
  }
}
