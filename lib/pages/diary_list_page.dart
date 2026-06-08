import 'package:flutter/material.dart';



import '../navigation/app_page_route.dart';

import '../services/diary_service.dart';

import '../services/echo_tree_service.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../services/locale_service.dart';

import '../widgets/echo_hub_carousel.dart';

import '../widgets/echo_page_header.dart';

import '../widgets/echo_themed_scope.dart';

import 'echo_records_page.dart';

import 'echo_tree_page.dart';

import 'photo_wall_page.dart';

import 'stats_page.dart';



/// 「回响」入口：四模块横向滑屏，默认首屏为留影。

class DiaryListPage extends StatefulWidget {

  const DiaryListPage({

    super.key,

    this.onWrite,

    this.highlightDiaryId,

    this.onHighlightConsumed,

  });



  final VoidCallback? onWrite;

  final String? highlightDiaryId;

  final VoidCallback? onHighlightConsumed;



  @override

  State<DiaryListPage> createState() => _DiaryListPageState();

}



class _DiaryListPageState extends State<DiaryListPage> {

  static List<String> get _moduleSubtitles => [
        tr(
          '日记里的照片，拼成一面会讲故事的墙',
          'Photos from echoes become a storytelling wall',
        ),
        tr(
          '按时间轴、月与周浏览你的文字',
          'Browse your words by timeline, month, or week',
        ),
        tr(
          '写回响得雨露，浇灌你的树',
          'Write echoes for dew — water your tree',
        ),
        tr(
          '看心情流转，也看阴晴圆缺',
          'Watch moods shift — sun and rain alike',
        ),
      ];



  final _diaryService = DiaryService.instance;

  final _treeService = EchoTreeService.instance;

  int _moduleIndex = 0;



  @override

  void initState() {

    super.initState();

    _diaryService.addListener(_onChanged);

    _treeService.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());

  }



  @override

  void didUpdateWidget(DiaryListPage oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.highlightDiaryId != null &&

        widget.highlightDiaryId != oldWidget.highlightDiaryId) {

      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());

    }

  }



  @override

  void dispose() {

    _diaryService.removeListener(_onChanged);

    _treeService.removeListener(_onChanged);

    super.dispose();

  }



  void _onChanged() {

    if (mounted) setState(() {});

  }



  void _handleDeepLink() {

    if (!mounted) return;

    if (widget.highlightDiaryId != null) {

      _openRecords();

    }

  }



  Future<void> _openRecords() async {

    await Navigator.of(context).push<void>(

      AppPageRoute<void>(

        builder: (_) => EchoRecordsPage(

          onWrite: widget.onWrite,

          highlightDiaryId: widget.highlightDiaryId,

          onHighlightConsumed: widget.onHighlightConsumed,

        ),

      ),

    );

  }



  Future<void> _openTree() async {

    await Navigator.of(context).push<void>(

      AppPageRoute<void>(builder: (_) => const EchoTreePage()),

    );

  }



  Future<void> _openPhotoWall() async {

    await Navigator.of(context).push<void>(

      AppPageRoute<void>(builder: (_) => const PhotoWallPage()),

    );

  }



  Future<void> _openStats() async {

    await Navigator.of(context).push<void>(

      AppPageRoute<void>(builder: (_) => const StatsPage()),

    );

  }



  @override

  Widget build(BuildContext context) {

    return EchoPageBackground(

      child: SafeArea(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            ListenableBuilder(
              listenable: LocaleService.instance,
              builder: (context, _) {
                return EchoPageHeader(
                  title: EchoStrings.of().echoTitle,
                  subtitle: _moduleSubtitles[_moduleIndex],
                );
              },
            ),

            Expanded(

              child: EchoHubCarousel(

                initialPage: 0,

                onModuleChanged: (index) {

                  if (_moduleIndex != index) {

                    setState(() => _moduleIndex = index);

                  }

                },

                onOpenPhoto: _openPhotoWall,

                onOpenRecords: _openRecords,

                onOpenTree: _openTree,

                onOpenStats: _openStats,

              ),

            ),

          ],

        ),

      ),

    );

  }

}


