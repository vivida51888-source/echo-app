import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/scale_tap.dart';
import 'write_diary_page.dart';

class DiaryDetailPage extends StatelessWidget {
  const DiaryDetailPage({super.key, required this.diaryId});

  final String diaryId;

  @override
  Widget build(BuildContext context) {
    final diary = DiaryService.instance.getDiaryById(diaryId);
    if (diary == null) {
      return Scaffold(
        backgroundColor: EchoColors.appBackground,
        body: Center(
          child: Text(
            '这篇回响已不在了',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EchoColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ScaleTap(
                    onTap: () => _showActions(context, diary),
                    scale: 0.9,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.more_horiz,
                        size: 22,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DiaryFormat.dateLine(diary.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (diary.moodWeather != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        diary.moodWeather!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                    ],
                    if (diary.hasImages) ...[
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: diary.images.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final path = diary.images[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(path, fit: BoxFit.cover)
                                : Image.file(File(path), fit: BoxFit.cover),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      diary.content,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                    ),
                    if (diary.hasAiInsight) ...[
                      const SizedBox(height: 36),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: EchoColors.daySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: EchoColors.dayDivider,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Echo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayTextSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              diary.aiSummary,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayTextPrimary,
                                height: 1.7,
                              ),
                            ),
                            if (diary.aiKeywords.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: diary.aiKeywords
                                    .map(
                                      (k) => Text(
                                        k,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
                                          color: EchoColors.dayTextSecondary,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Diary diary) async {
    final action = await showEchoActionSheet<String>(
      context: context,
      actions: const [
        EchoActionSheetItem(label: '编辑', value: 'edit'),
        EchoActionSheetItem(
          label: '删除',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'edit':
        final saved = await Navigator.of(context).push<bool>(
          AppPageRoute<bool>(
            builder: (_) => WriteDiaryPage(editingDiary: diary),
          ),
        );
        if (saved == true && context.mounted) {
          Navigator.pop(context, true);
        }
      case 'delete':
        final confirm = await showEchoActionSheet<bool>(
          context: context,
          message: '删除这篇回响？',
          actions: const [
            EchoActionSheetItem(
              label: '删除',
              value: true,
              isDestructive: true,
            ),
          ],
        );
        if (confirm == true) {
          await DiaryService.instance.deleteDiary(diary.id);
          if (context.mounted) Navigator.pop(context, true);
        }
    }
  }
}
