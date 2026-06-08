import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../theme/echo_colors.dart';
import 'scale_tap.dart';

/// 编辑海报文案并确认保存。
Future<String?> showPhotoWallExportSheet(
  BuildContext context, {
  required String periodTitle,
  required String defaultCaption,
  required int photoCount,
  String? savedCaption,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: EchoColors.appBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PhotoWallExportSheet(
      periodTitle: periodTitle,
      initialCaption: _resolveInitialCaption(savedCaption, defaultCaption),
      photoCount: photoCount,
    ),
  );
}

String _resolveInitialCaption(String? saved, String fallback) {
  final savedTrim = saved?.trim() ?? '';
  if (savedTrim.isNotEmpty) return savedTrim;
  return fallback.trim();
}

class _PhotoWallExportSheet extends StatefulWidget {
  const _PhotoWallExportSheet({
    required this.periodTitle,
    required this.initialCaption,
    required this.photoCount,
  });

  final String periodTitle;
  final String initialCaption;
  final int photoCount;

  @override
  State<_PhotoWallExportSheet> createState() => _PhotoWallExportSheetState();
}

class _PhotoWallExportSheetState extends State<_PhotoWallExportSheet> {
  late final TextEditingController _controller;
  static List<String> get _suggestions => [
        tr(
          '这些日子，也悄悄留下了一帧帧画面',
          'These days quietly left frame after frame',
        ),
        tr(
          '散落的照片，拼成一面会讲故事的墙',
          'Scattered photos became a storytelling wall',
        ),
        tr(
          '把寻常日子，贴成可以回看的风景',
          'Ordinary days pinned as scenery to revisit',
        ),
        tr(
          '每一张，都是写给未来的便签',
          'Each one a note to your future self',
        ),
      ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCaption);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EchoColors.dayDivider.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('保存海报', 'Save poster'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.periodTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextWhisper,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('海报文案', 'Poster caption'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLength: 80,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText: tr(
                '写一句想留在海报上的话',
                'A line to keep on the poster',
              ),
              hintStyle: TextStyle(
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextWhisper,
              ),
              filled: true,
              fillColor: EchoColors.dayWriting.withValues(alpha: 0.65),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: EchoColors.dayTextSecondary.withValues(alpha: 0.45),
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              counterStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextWhisper,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final line in _suggestions)
                ScaleTap(
                  onTap: () => setState(() => _controller.text = line),
                  scale: 0.97,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: EchoColors.dayWriting.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: EchoColors.dayDivider.withValues(alpha: 0.45),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          ScaleTap(
            onTap: _confirm,
            scale: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: EchoColors.dayTextPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.photoCount == 0
                    ? tr('保存空白海报', 'Save blank poster')
                    : tr('保存到相册', 'Save to Photos'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.daySurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
