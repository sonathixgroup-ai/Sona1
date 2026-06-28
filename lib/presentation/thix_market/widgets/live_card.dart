import 'package:flutter/material.dart';
import 'package:thix_id/models/market_live.dart';
import 'package:thix_id/theme.dart';

class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.live, this.onTap});

  final MarketLive live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        highlightColor: Colors.transparent,
        child: Container(
          width: 160,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.stroke)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: MarketColors.bg,
                  child: live.coverImageUrl == null || live.coverImageUrl!.trim().isEmpty
                      ? const Center(child: Icon(Icons.videocam_outlined, color: MarketColors.grayText))
                      : Image.network(live.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
                      stops: const [0, 0.75],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: live.isLive ? Colors.red : MarketColors.grayText, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    live.isLive ? 'LIVE' : 'REPLAY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${live.viewers}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    if (live.hostName != null && live.hostName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        live.hostName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
