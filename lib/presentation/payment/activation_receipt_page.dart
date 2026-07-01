// lib/presentation/activation/activation_receipt_page.dart

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

/// ✅ GARDE UNIQUEMENT theme
/// ❌ SUPPRIME textStyles pour éviter le conflit
extension ReceiptThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
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

  Future<String> _assignRealThixIdIfMissing({
    required String uid,
  }) async {
    final profile =
        await _profiles.fetchPublicProfileByUserId(uid);

    if (profile != null &&
        !_isPendingThixId(profile.thixId)) {
      return profile.thixId;
    }

    /// ✅ CORRECTION
    /// ❌ thixId:
    /// ✅ uid:
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

    setState(() {
      _ensuringThixId = true;
    });

    try {
      final real =
          await _assignRealThixIdIfMissing(uid: me.id);

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
        setState(() {
          _ensuringThixId = false;
        });
      }
    }
  }

  bool _isPendingThixId(String thixId) {
    final v = thixId.trim().toUpperCase();

    return v.isEmpty ||
        v == 'THIX-PENDING' ||
        v == 'THIX-000000';
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
          'created_at': (widget.paidAt ??
                  DateTime.now().toUtc())
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
                pw.SizedBox(height: 12),
                pw.Text('Transaction ID: $txId'),
                pw.Text('Amount: $amount $currency'),
                pw.Text('Date: $dateTime'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Status: VERIFIED',
                  style: pw.TextStyle(
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
      return Scaffold(
        backgroundColor: const Color(0xFF0A2F5C),
        body: Center(
          child: Text(
            'Session requise.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      );
    }

    return StreamBuilder<ThixProfile?>(
      stream: _profiles.streamMyProfile(me.id),
      builder: (context, snap) {
        final p = snap.data;

        final thixIdCandidate =
            me.thixId.trim();

        final thixId = (_isPendingThixId(
                  thixIdCandidate,
                )
                ? (p?.thixId ??
                    thixIdCandidate)
                : thixIdCandidate)
            .trim()
            .toUpperCase();

        final chatId = me.thixChat.trim();

        final fullName =
            me.displayName.trim().isEmpty
                ? 'Utilisateur'
                : me.displayName.trim();

        final country =
            me.countryOrOrigin?.trim() ??
                '—';

        final url =
            'https://thix.id/user/$thixId';

        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchLatestPayment(me.id),
          builder: (context, paySnap) {
            final payment = paySnap.data;

            final txId = (payment?['tx_ref'] ??
                    widget.txRef ??
                    '—')
                .toString();

            final method = (payment?['method'] ??
                    widget.method ??
                    '—')
                .toString();

            final amount = (payment?['amount'] ??
                    widget.amount ??
                    '5.00')
                .toString();

            final currency =
                (payment?['currency'] ??
                        widget.currency ??
                        'USD')
                    .toString();

            final createdRaw =
                payment?['created_at'];

            final paidAt = createdRaw is String
                ? DateTime.tryParse(createdRaw)
                : null;

            final dateTime =
                _fmtTs(widget.paidAt ?? paidAt);

            Future<void> downloadPdf() async {
              if (_busy) return;

              setState(() {
                _busy = true;
              });

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
                  'ActivationReceipt pdf error: $e',
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _busy = false;
                  });
                }
              }
            }

            Future<void> shareReceipt() async {
              final text = '''
THIX ID Activated

THIX ID: $thixId
Chat ID: $chatId
Name: $fullName
Country: $country

Transaction: $txId
Amount: $amount $currency
Method: $method

Status: VERIFIED

$url
''';

              try {
                await Share.share(text);
              } catch (e) {
                debugPrint(
                  'ActivationReceipt share error: $e',
                );
              }
            }

            return Scaffold(
              backgroundColor:
                  const Color(0xFF0A2F5C),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              final t = auth
                                  .currentUser
                                  ?.accountType;

                              context.go(
                                t == AccountType
                                        .enterprise
                                    ? AppRoutes
                                        .enterpriseDashboard
                                    : AppRoutes
                                        .userDashboard,
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: AppSpacing.sm,
                          ),
                          Expanded(
                            child: Text(
                              'Reçu d’activation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      Container(
                        padding:
                            const EdgeInsets.all(
                          AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            AppRadius.xl,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  Color(0xFF17B26A),
                              size: 80,
                            ),

                            const SizedBox(
                              height:
                                  AppSpacing.md,
                            ),

                            Text(
                              'THIX ID Successfully Activated',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            const Color(
                                          0xFF0A3D62,
                                        ),
                                      ),
                            ),

                            const SizedBox(
                              height:
                                  AppSpacing.lg,
                            ),

                            SelectableText(
                              thixId,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                            ),

                            const SizedBox(
                              height:
                                  AppSpacing.lg,
                            ),

                            _ReceiptRow(
                              label: 'Chat ID',
                              value: chatId,
                            ),

                            _ReceiptRow(
                              label: 'Full Name',
                              value: fullName,
                            ),

                            _ReceiptRow(
                              label: 'Country',
                              value: country,
                            ),

                            _ReceiptRow(
                              label: 'Date',
                              value: dateTime,
                            ),

                            _ReceiptRow(
                              label:
                                  'Transaction',
                              value: txId,
                            ),

                            _ReceiptRow(
                              label: 'Payment',
                              value:
                                  '$amount $currency · $method',
                            ),

                            const SizedBox(
                              height:
                                  AppSpacing.lg,
                            ),

                            QrImageView(
                              data: url,
                              size: 160,
                              backgroundColor:
                                  Colors.white,
                            ),

                            const SizedBox(
                              height:
                                  AppSpacing.sm,
                            ),

                            Text(
                              url,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      ElevatedButton.icon(
                        onPressed:
                            _busy
                                ? null
                                : downloadPdf,
                        icon: const Icon(
                          Icons.download,
                        ),
                        label: Text(
                          _busy
                              ? 'Préparation...'
                              : 'Download PDF',
                        ),
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      OutlinedButton.icon(
                        onPressed:
                            shareReceipt,
                        icon: const Icon(
                          Icons.share_rounded,
                        ),
                        label:
                            const Text('Share'),
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          context.go(
                            '${AppRoutes.publicProfile}?thixId=${Uri.encodeComponent(thixId)}',
                          );
                        },
                        icon: const Icon(
                          Icons.public,
                          color:
                              Color(0xFF0A2F5C),
                        ),
                        label: const Text(
                          'View Public Profile',
                          style: TextStyle(
                            color:
                                Color(0xFF0A2F5C),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              LightModeColors
                                  .accent,
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
            ),
          ),
        ],
      ),
    );
  }
}
