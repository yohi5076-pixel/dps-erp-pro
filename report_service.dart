import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/customer_model.dart';
import 'firestore_service.dart';

class DashboardSummary {
  final double totalRevenue;
  final double totalOutstanding;
  final int totalInvoices;
  final int totalCustomers;
  final int unpaidInvoices;
  final int overdueInvoices;

  DashboardSummary({
    required this.totalRevenue,
    required this.totalOutstanding,
    required this.totalInvoices,
    required this.totalCustomers,
    required this.unpaidInvoices,
    required this.overdueInvoices,
  });
}

class CustomerLedgerEntry {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;

  CustomerLedgerEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

class ReportService {
  ReportService._internal();
  static final ReportService instance = ReportService._internal();

  double invoicePaidAmount(InvoiceModel invoice, List<PaymentModel> payments) {
    return payments
        .where((p) => p.invoiceId == invoice.id)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double invoiceBalanceDue(InvoiceModel invoice, List<PaymentModel> payments) {
    final paid = invoicePaidAmount(invoice, payments);
    final due = invoice.grandTotal - paid;
    return due < 0 ? 0 : due;
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final invoices = await FirestoreService.instance.getInvoices();
    final payments = await FirestoreService.instance.getPayments();
    final customers = await FirestoreService.instance.getCustomers();

    double revenue = 0;
    double outstanding = 0;
    int unpaid = 0;
    int overdue = 0;
    final now = DateTime.now();

    for (final invoice in invoices) {
      if (invoice.status == InvoiceStatus.cancelled) continue;
      final paid = invoicePaidAmount(invoice, payments);
      revenue += paid;
      final due = invoiceBalanceDue(invoice, payments);
      outstanding += due;
      if (due > 0) {
        unpaid++;
        if (invoice.dueDate.isBefore(now)) overdue++;
      }
    }

    return DashboardSummary(
      totalRevenue: revenue,
      totalOutstanding: outstanding,
      totalInvoices: invoices.length,
      totalCustomers: customers.length,
      unpaidInvoices: unpaid,
      overdueInvoices: overdue,
    );
  }

  Future<List<CustomerLedgerEntry>> getCustomerLedger(CustomerModel customer) async {
    final invoices = (await FirestoreService.instance.getInvoices())
        .where((i) => i.customerId == customer.id && i.status != InvoiceStatus.cancelled)
        .toList();
    final payments = (await FirestoreService.instance.getPayments())
        .where((p) => p.customerId == customer.id)
        .toList();

    final entries = <CustomerLedgerEntry>[];
    double balance = customer.openingBalance;

    final events = <MapEntry<DateTime, CustomerLedgerEntry Function(double)>>[];

    for (final inv in invoices) {
      events.add(MapEntry(
        inv.issueDate,
        (bal) => CustomerLedgerEntry(
          date: inv.issueDate,
          description: 'Invoice ${inv.invoiceNumber}',
          debit: inv.grandTotal,
          credit: 0,
          runningBalance: bal,
        ),
      ));
    }
    for (final pay in payments) {
      events.add(MapEntry(
        pay.paidAt,
        (bal) => CustomerLedgerEntry(
          date: pay.paidAt,
          description: 'Payment received (${pay.method.name})',
          debit: 0,
          credit: pay.amount,
          runningBalance: bal,
        ),
      ));
    }

    events.sort((a, b) => a.key.compareTo(b.key));

    for (final e in events) {
      final placeholder = e.value(0);
      balance += placeholder.debit - placeholder.credit;
      entries.add(CustomerLedgerEntry(
        date: placeholder.date,
        description: placeholder.description,
        debit: placeholder.debit,
        credit: placeholder.credit,
        runningBalance: balance,
      ));
    }

    return entries;
  }

  Future<List<InvoiceModel>> getOverdueInvoices() async {
    final invoices = await FirestoreService.instance.getInvoices();
    final payments = await FirestoreService.instance.getPayments();
    final now = DateTime.now();
    return invoices.where((inv) {
      if (inv.status == InvoiceStatus.cancelled) return false;
      final due = invoiceBalanceDue(inv, payments);
      return due > 0 && inv.dueDate.isBefore(now);
    }).toList();
  }
}
