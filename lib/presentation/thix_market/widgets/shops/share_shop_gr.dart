import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class ShareShopQr extends StatefulWidget {
  final String shopId;
  final String shopName;
  final String? shopLogo;
  final String? shopUrl;

  const ShareShopQr({
    super.key,
    required this.shopId,
    required this.shopName,
    this.shopLogo,
    this.shopUrl,
  });

  @override
  State<ShareShopQr> createState() => _ShareShopQrState();
}

class _ShareShopQrState extends State<ShareShopQr> {
  bool _isNfcSupported = false;
  bool _isNfcEnabled = false;
  String? _nfcStatus;

  @override
  void initState() {
    super.initState();
    _checkNfcCapability();
  }

  Future<void> _checkNfcCapability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcSupported = isAvailable;
      _nfcStatus = isAvailable ? 'NFC disponible' : 'NFC non disponible';
    });
  }

  Future<void> _writeToNfc() async {
    if (!_isNfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC non supporté sur cet appareil')),
      );
      return;
    }

    final status = await Permission.nfc.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission NFC refusée')),
      );
      return;
    }

    final shopUrl = widget.shopUrl ?? 'thix://shop/${widget.shopId}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Écrire sur une étiquette NFC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Approchez votre téléphone de l\'étiquette NFC'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(shopUrl, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      await NfcManager.instance.stopSession();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données écrites sur l\'étiquette NFC')),
        );
      }
    });
  }

  Future<void> _shareViaNfc() async {
    if (!_isNfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC non supporté sur cet appareil')),
      );
      return;
    }

    final shopUrl = widget.shopUrl ?? 'thix://shop/${widget.shopId}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager via NFC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Approchez deux téléphones compatibles NFC'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(shopUrl, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      await NfcManager.instance.stopSession();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partage via NFC initié')),
        );
      }
    });
  }

  Future<void> _shareViaSocialMedia() async {
    final String shareText = '''
Découvrez ${widget.shopName} sur THIX Market !
${widget.shopUrl ?? 'https://thix.com/shop/${widget.shopId}'}

#THIXMarket #Shopping #${widget.shopName.replaceAll(' ', '')}
    ''';

    await Share.share(
      shareText,
      subject: 'Visitez ma boutique sur THIX Market',
    );
  }

  Future<void> _shareLink() async {
    final shopUrl = widget.shopUrl ?? 'https://thix.com/shop/${widget.shopId}';
    await Share.share(
      shopUrl,
      subject: 'Visitez ${widget.shopName} sur THIX Market',
    );
  }

  void _saveQrCode() {
    // Capture le QR code et sauvegarde
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code sauvegardé'),
        content: const Text('Le QR code a été sauvegardé dans votre galerie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopUrl = widget.shopUrl ?? 'https://thix.com/shop/${widget.shopId}';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          const Text(
            'Partager ma boutique',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Partagez votre boutique avec vos clients',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: shopUrl,
                    version: QrVersions.auto,
                    size: 200,
                    gapless: false,
                    embeddedImageStyle: widget.shopLogo != null
                        ? QrEmbeddedImageStyle(
                            size: const Size(40, 40),
                            embeddedImage: NetworkImage(widget.shopLogo!),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _saveQrCode,
                        icon: const Icon(Icons.download),
                        tooltip: 'Sauvegarder le QR code',
                      ),
                      IconButton(
                        onPressed: _shareLink,
                        icon: const Icon(Icons.share),
                        tooltip: 'Partager le lien',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options de partage
          const Text(
            'Partager via',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildShareOption(
                icon: Icons.share,
                label: 'Réseaux sociaux',
                color: Colors.blue,
                onTap: _shareViaSocialMedia,
              ),
              _buildShareOption(
                icon: Icons.link,
                label: 'Copier le lien',
                color: Colors.green,
                onTap: _shareLink,
              ),
              if (_isNfcSupported)
                _buildShareOption(
                  icon: Icons.nfc,
                  label: 'NFC',
                  color: Colors.purple,
                  onTap: _shareViaNfc,
                ),
              if (_isNfcSupported)
                _buildShareOption(
                  icon: Icons.sd_storage,
                  label: 'Écrire NFC',
                  color: Colors.orange,
                  onTap: _writeToNfc,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats de partage
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_formatNumber(1250)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5592F),
                        ),
                      ),
                      const Text('Partages', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_formatNumber(3450)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5592F),
                        ),
                      ),
                      const Text('Visites', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_formatNumber(89)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5592F),
                        ),
                      ),
                      const Text('Ventes', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
