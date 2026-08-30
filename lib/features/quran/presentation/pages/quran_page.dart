import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quran_reading_position.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../widgets/quran_state_view.dart';
import '../widgets/reciter_selector.dart';
import '../widgets/surah_list_tile.dart';

class QuranPage extends GetView<QuranController> {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<QuranAudioController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('quran'.tr),
        actions: [
          ReciterSelectorButton(controller: audioController, iconOnly: true),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => controller.loadSurahs(forceRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuranWelcomeCard(controller: controller),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: controller.search,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'quran_search_hint'.tr,
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Obx(() => _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) =>
      switch (controller.status.value) {
        QuranViewStatus.loading => SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: const QuranLoadingView(),
            ),
          ),
        ),
        QuranViewStatus.error => SliverFillRemaining(
          hasScrollBody: false,
          child: QuranStateView(
            messageKey: controller.errorKey.value,
            onRetry: () => controller.loadSurahs(forceRefresh: true),
          ),
        ),
        QuranViewStatus.success when controller.filteredSurahs.isEmpty =>
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('quran_no_search_results'.tr)),
          ),
        QuranViewStatus.success => SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
          sliver: SliverList.builder(
            itemCount: controller.filteredSurahs.length * 2 - 1,
            itemBuilder: (context, index) {
              if (index.isOdd) return const SizedBox(height: 10);
              final surah = controller.filteredSurahs[index ~/ 2];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: SurahListTile(
                    surah: surah,
                    onTap: () => controller.openSurah(surah),
                  ),
                ),
              );
            },
          ),
        ),
      };
}

class _QuranWelcomeCard extends StatelessWidget {
  const _QuranWelcomeCard({required this.controller});

  final QuranController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.deepEmerald, AppColors.emerald],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Obx(() {
      final position = controller.lastReadingPosition.value;
      final surah = _surahForPosition(controller.surahs, position);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'quran_read_reflect'.tr,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'quran_read_reflect_message'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          if (position != null && surah != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.deepEmerald,
              ),
              onPressed: controller.continueReading,
              icon: const Icon(Icons.bookmark_rounded),
              label: Text(
                '${'quran_continue_reading'.tr}: ${surah.englishName} • '
                '${'quran_ayah_number'.trParams({'number': '${position.ayahNumber}'})}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );
    }),
  );
}

Surah? _surahForPosition(List<Surah> surahs, QuranReadingPosition? position) {
  if (position == null) return null;
  for (final surah in surahs) {
    if (surah.number == position.surahNumber) return surah;
  }
  return null;
}
