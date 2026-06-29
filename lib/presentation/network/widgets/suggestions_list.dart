import 'package:flutter/material.dart';
import 'package:thix_id/models/network_connection.dart';

class SuggestionsList extends StatefulWidget {
  final List<NetworkConnection> suggestions;
  final Function(String) onConnect;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.onConnect,
  });

  @override
  State<SuggestionsList> createState() => _SuggestionsListState();
}

class _SuggestionsListState extends State<SuggestionsList> {
  Set<String> _connectingIds = {};

  Future<void> _handleConnect(String id) async {
    setState(() => _connectingIds.add(id));
    await widget.onConnect(id);
    setState(() => _connectingIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Aucune suggestion pour le moment',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Revenez plus tard pour découvrir de nouvelles connexions',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final connection = widget.suggestions[index];
        final mutualCount = connection.mutualConnections ?? 0;
        final isConnecting = _connectingIds.contains(connection.id);
        final avatarText = connection.name.isNotEmpty ? connection.name[0].toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: connection.avatar != null && connection.avatar!.isNotEmpty
                    ? NetworkImage(connection.avatar!)
                    : null,
                child: connection.avatar == null || connection.avatar!.isEmpty
                    ? Text(
                        avatarText,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connection.title,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$mutualCount connexion${mutualCount > 1 ? 's' : ''} commune${mutualCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: isConnecting ? null : () => _handleConnect(connection.id),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(90, 32),
                ),
                child: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD4AF37),
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37)),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
