// ✅ activation_receipt_page.dart CORRIGÉ
// Correction principale : suppression complète de "thixld"
// Remplacé partout par "thixId"

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

extension ReceiptThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textStyles => Theme.of(this).textTheme;
}

class ActivationReceiptPage extends StatefulWidget {
  final String? txRef;
  final String? method;
  final String? amount;
  final String? currency;
  final DateTime? paidAt;

  const ActivationReceiptPage({
    super.key,
    this.txRef,
    this.method,
    this.amount,
    this.currency,
    this.paidAt,
  });

  @override
  State<ActivationReceiptPage> createState() =>
      _ActivationReceiptPageState();
}

class _ActivationReceiptPageState
    extends State<ActivationReceiptPage> {
  final _profiles = ProfileService();

  bool _busy = false;
  bool _ensuringThixId = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRealThixId();
    });
  }

  bool _isPendingThixId(String thixId) {
    final v = thixId.trim().toUpperCase();

    return v.isEmpty ||
        v == 'THIX-PENDING' ||
        v == 'THIX-000000';
  }

  Future<String> _assignRealThixIdIfMissing({
    required String uid,
  }) async {
    final profile =
        await _profiles.fetchPublicProfileByUserId(uid);

    if (profile != null &&
        !_isPendingThixId(profile.thixId)) {
      return profile.thixId;
    }

    final newId =
        await _profiles.generateThixId(uid: uid);

    await _profiles.updateProfile(
      userId: uid,
      thixId: newId,
    );

    return newId;
  }

  Future<void> _ensureRealThixId() async {
    if (_ensuringThixId) return;

    final auth = context.read<AuthController>();

    final me = auth.currentUser;

    if (me == null) return;

    if (!_isPendingThixId(me.thixId)) return;

    setState(() => _ensuringThixId = true);

    try {
      final real = await _assignRealThixIdIfMissing(
        uid: me.id,
      );

      // ✅ CORRIGÉ
      await auth.updateCurrentUser(
        me.copyWith(
          thixId: real,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint(
        'ActivationReceipt ensureRealThixId error: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _ensuringThixId = false);
      }
    }
  }

  String _fmtTs(DateTime? dt) {
    final safe = dt ?? DateTime.now();

    final m = safe.month.toString().padLeft(2, '0');
    final d = safe.day.toString().padLeft(2, '0');
    final h = safe.hour.toString().padLeft(2, '0');
    final min = safe.minute.toString().padLeft(2, '0');

    return '${safe.year}-$m-$d  $h:$min';
  }

  Future<Map<String, dynamic>?> _fetchLatestPayment(
    String uid,
  ) async {
    try {
      if ((widget.txRef ?? '').trim().isNotEmpty) {
        return {
          'tx_ref': widget.txRef,
          'method': widget.method,
          'amount': widget.amount,
          'currency': widget.currency,
          'created_at':
              (widget.paidAt ?? DateTime.now().toUtc())
                  .toIso8601String(),
        };
      }

      final row = await SupabaseConfig.client
          .from('thix_payments')
          .select('*')
          .eq('user_id', uid)
          .order(
            'created_at',
            ascending: false,
          )
          .limit(1)
          .maybeSingle();

      return row == null
          ? null
          : (row as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint(
        'ActivationReceipt fetchLatestPayment error: $e',
      );

      return null;
    }
  }

  Future<Uint8List> _buildPdf({
    required String thixId,
    required String chatId,
    required String fullName,
    required String country,
    required String txId,
    required String amount,
    required String currency,
    required String dateTime,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'THIX ID Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Text('THIX ID: $thixId'),
                pw.Text('Chat ID: $chatId'),
                pw.Text('Full Name: $fullName'),
                pw.Text('Country: $country'),

                pw.SizedBox(height: 20),

                pw.Text('Transaction ID: $txId'),
                pw.Text(
                  'Amount: $amount $currency',
                ),
                pw.Text('Date: $dateTime'),

                pw.SizedBox(height: 20),

                pw.Text(
                  'STATUS: VERIFIED',
                  style: pw.TextStyle(
                    color: PdfColors.green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    final me = auth.currentUser;

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text('Session requise'),
        ),
      );
    }

    return StreamBuilder<ThixProfile?>(
      stream: _profiles.streamMyProfile(me.id),
      builder: (context, snap) {
        final p = snap.data;

        final thixIdCandidate =
            me.thixId.trim();

        final thixId =
            (_isPendingThixId(thixIdCandidate)
                    ? (p?.thixId ?? thixIdCandidate)
                    : thixIdCandidate)
                .trim()
                .toUpperCase();

        final chatId =
            (me.thixChat.trim().isNotEmpty
                    ? me.thixChat
                    : (p?.thixChat ?? ''))
                .trim();

        final fullName =
            (me.displayName.trim().isNotEmpty
                    ? me.displayName
                    : (p?.displayName ??
                        'Utilisateur'))
                .trim();

        final country =
            (p?.countryOrOrigin ?? '—').trim();

        // ✅ CORRIGÉ
        final url =
            'https://thix.id/user/$thixId';

        return FutureBuilder<
            Map<String, dynamic>?>(
          future: _fetchLatestPayment(me.id),
          builder: (context, paySnap) {
            final payment = paySnap.data;

            final txId =
                (payment?['tx_ref'] ??
                        widget.txRef ??
                        '—')
                    .toString();

            final method =
                (payment?['method'] ??
                        widget.method ??
                        '—')
                    .toString();

            final amount =
                (payment?['amount'] ??
                        widget.amount ??
                        '5.00')
                    .toString();

            final currency =
                (payment?['currency'] ??
                        widget.currency ??
                        'USD')
                    .toString();

            final dateTime =
                _fmtTs(widget.paidAt);

            Future<void> downloadPdf() async {
              if (_busy) return;

              setState(() => _busy = true);

              try {
                final bytes = await _buildPdf(
                  thixId: thixId,
                  chatId: chatId,
                  fullName: fullName,
                  country: country,
                  txId: txId,
                  amount: amount,
                  currency: currency,
                  dateTime: dateTime,
                );

                await Printing.sharePdf(
                  bytes: bytes,
                  filename:
                      'THIX_ID_Receipt_$thixId.pdf',
                );
              } catch (e) {
                debugPrint(
                  'ActivationReceipt PDF error: $e',
                );
              } finally {
                if (mounted) {
                  setState(() => _busy = false);
                }
              }
            }

            Future<void> shareReceipt() async {
              try {
                await Share.share(
                  '''
THIX ID Activated

THIX ID: $thixId
Chat ID: $chatId
Name: $fullName
Country: $country

TX: $txId
Amount: $amount $currency

$url
''',
                );
              } catch (e) {
                debugPrint(
                  'ActivationReceipt share error: $e',
                );
              }
            }

            return Scaffold(
              backgroundColor:
                  const Color(0xFF0A2F5C),

              appBar: AppBar(
                backgroundColor:
                    const Color(0xFF0A2F5C),
                elevation: 0,
                title: const Text(
                  'Reçu d’activation',
                ),
              ),

              body: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 80,
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'THIX ID ACTIVATED',
                            style: context
                                .textStyles
                                .headlineSmall
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 24),

                          SelectableText(
                            thixId,
                            style: context
                                .textStyles
                                .headlineMedium
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 24),

                          QrImageView(
                            data: url,
                            size: 180,
                          ),

                          const SizedBox(height: 20),

                          Text(url),

                          const SizedBox(height: 24),

                          _ReceiptRow(
                            label:
                                'Transaction ID',
                            value: txId,
                          ),

                          _ReceiptRow(
                            label: 'Amount',
                            value:
                                '$amount $currency',
                          ),

                          _ReceiptRow(
                            label: 'Method',
                            value: method,
                          ),

                          _ReceiptRow(
                            label: 'Date',
                            value: dateTime,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed:
                          _busy ? null : downloadPdf,
                      icon: const Icon(
                        Icons.download,
                      ),
                      label: Text(
                        _busy
                            ? 'Préparation...'
                            : 'Télécharger PDF',
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: shareReceipt,
                      icon: const Icon(
                        Icons.share,
                      ),
                      label: const Text(
                        'Partager',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context
                  .textStyles
                  .bodyMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
