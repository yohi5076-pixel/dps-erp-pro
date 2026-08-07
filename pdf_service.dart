import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../utils/constants.dart';

class PdfService {
  PdfService._internal();
  static final PdfService instance = PdfService._internal();

  final _dateFmt = DateFormat('dd MMM yyyy');
  final _currencyFmt = NumberFormat.currency(symbol: AppConstants.currencySymbol, decimalDigits: 2);

  Future<Uint8List> buildInvoicePdf({
    required InvoiceModel invoice,
    required CustomerModel customer,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(AppConstants.appName,
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('# ${invoice.invoiceNumber}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.name),
                      if (customer.address.isNotEmpty) pw.Text(customer.address),
                      if (customer.phone.isNotEmpty) pw.Text(customer.phone),
                      if (customer.gstNumber.isNotEmpty) pw.Text('GSTIN: ${customer.gstNumber}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Issue Date: ${_dateFmt.format(invoice.issueDate)}'),
                      pw.Text('Due Date: ${_dateFmt.format(invoice.dueDate)}'),
                      pw.Text('Status: ${invoice.status.name.toUpperCase()}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Description', bold: true),
                      _cell('Qty', bold: true),
                      _cell('Rate', bold: true),
                      _cell('Amount', bold: true),
                    ],
                  ),
                  ...invoice.items.map((item) => pw.TableRow(children: [
                        _cell(item.description),
                        _cell(item.quantity.toStringAsFixed(2)),
                        _cell(_currencyFmt.format(item.rate)),
                        _cell(_currencyFmt.format(item.total)),
                      ])),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _totalsRow('Subtotal', invoice.subtotal, _currencyFmt),
                    _totalsRow('Tax (${invoice.taxPercent.toStringAsFixed(1)}%)', invoice.taxAmount, _currencyFmt),
                    _totalsRow('Discount', -invoice.discount, _currencyFmt),
                    pw.Divider(),
                    _totalsRow('Grand Total', invoice.grandTotal, _currencyFmt, bold: true),
                  ],
                ),
              ),
              if (invoice.notes.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.notes),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  pw.Widget _totalsRow(String label, double value, NumberFormat fmt, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ),
          pw.SizedBox(
            width: 100,
            child: pw.Text(fmt.format(value),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  Future<void> shareOrPrintInvoice({
    required InvoiceModel invoice,
    required CustomerModel customer,
  }) async {
    final bytes = await buildInvoicePdf(invoice: invoice, customer: customer);
    await Printing.sharePdf(bytes: bytes, filename: 'Invoice_${invoice.invoiceNumber}.pdf');
  }
}
