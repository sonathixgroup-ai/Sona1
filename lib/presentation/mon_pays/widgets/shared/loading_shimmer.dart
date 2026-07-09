// lib/presentation/mon_pays/widgets/shared/loading_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget générique pour afficher un effet de chargement (skeleton shimmer)
/// Adapté aux différentes mises en page du module Mon Pays.
class LoadingShimmer extends StatelessWidget {
  final LoadingShimmerType type;
  final int itemCount;

  const LoadingShimmer({
    Key? key,
    this.type = LoadingShimmerType.horizontalCards,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundLight,
      highlightColor: Colors.grey.shade200,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case LoadingShimmerType.horizontalCards:
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            itemBuilder: (_, __) => _horizontalCardPlaceholder(),
          ),
        );
      case LoadingShimmerType.verticalNews:
        return Column(
          children: List.generate(
            itemCount,
            (index) => _verticalNewsPlaceholder(),
          ),
        );
      case LoadingShimmerType.grid:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: itemCount,
            itemBuilder: (_, __) => _gridPlaceholder(),
          ),
        );
      case LoadingShimmerType.historicalFigures:
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            itemBuilder: (_, __) => _historyCardPlaceholder(),
          ),
        );
      case LoadingShimmerType.videos:
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            itemBuilder: (_, __) => _videoPlaceholder(),
          ),
        );
      case LoadingShimmerType.wanted:
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            itemBuilder: (_, __) => _wantedPlaceholder(),
          ),
        );
      case LoadingShimmerType.custom:
        // Pour des cas particuliers, on peut utiliser un container simple
        return Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
        );
    }
  }

  // Placeholders
  Widget _horizontalCardPlaceholder() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 60,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _verticalNewsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 100,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 50,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _historyCardPlaceholder() {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 50,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 120,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _wantedPlaceholder() {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 80,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                height: 10,
                width: 80,
                color: Colors.grey.shade300,
              ),
              const Spacer(),
              Container(
                height: 16,
                width: 40,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 30,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

/// Types de mise en page pour le shimmer
enum LoadingShimmerType {
  horizontalCards,
  verticalNews,
  grid,
  historicalFigures,
  videos,
  wanted,
  custom,
}
