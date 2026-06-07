import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diary.dart';
import '../models/weather_mood.dart';
import '../services/diary_draft_service.dart';
import '../services/diary_image_storage.dart';
import '../services/diary_service.dart';
import '../pages/diary_stationery_page.dart';
import '../services/diary_stationery_service.dart';
import '../services/location_service.dart';
import '../services/mock_ai_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_copy.dart';
import '../utils/diary_format.dart';
import '../utils/diary_write_chrome.dart';
import '../widgets/diary_stationery_backdrop.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/scale_tap.dart';

class WriteDiaryPage extends StatefulWidget {
  const WriteDiaryPage({
    super.key,
    this.editingDiary,
    this.fromEmotionalEntry = false,
    this.initialContent,
  });

  final Diary? editingDiary;
  final bool fromEmotionalEntry;
  final String? initialContent;

  bool get isEditing => editingDiary != null;

  @override
  State<WriteDiaryPage> createState() => _WriteDiaryPageState();
}

class _WriteSnapshot {
  const _WriteSnapshot({
    required this.content,
    required this.moodWeather,
    required this.images,
    required this.recordedAt,
  });

  final String content;
  final String? moodWeather;
  final List<String> images;
  final DateTime recordedAt;
}

class _WriteDiaryPageState extends State<WriteDiaryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxImages = 9;

  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _pageScrollController = ScrollController();
  double _lastKeyboardInset = 0;
  final _imagePicker = ImagePicker();

  final List<String> _imagePaths = [];
  String? _selectedWeather;
  Timer? _previewTimer;
  Timer? _draftTimer;
  bool _saving = false;
  bool _showSaveSuccess = false;
  bool _suppressDraftPersist = false;
  late AnimationController _saveAnimController;
  late Animation<double> _saveScale;
  late Animation<double> _saveOpacity;
  late _WriteSnapshot _initialSnapshot;
  String? _previewSummary;
  List<String> _previewKeywords = [];
  late final String _draftId;
  late DateTime _recordedAt;
  DiaryLocation? _location;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftId = widget.editingDiary?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final diary = widget.editingDiary;
    if (diary != null) {
      _contentController.text = diary.content;
      _selectedWeather = diary.moodWeather;
      _imagePaths.addAll(diary.images);
      _previewSummary = diary.aiSummary;
      _previewKeywords = diary.aiKeywords;
      _recordedAt = diary.createdAt;
      if (diary.hasLocation) {
        final label = diary.placeLabel?.trim() ?? '';
        _location = DiaryLocation(
          latitude: diary.latitude!,
          longitude: diary.longitude!,
          placeLabel: label.isNotEmpty
              ? label
              : '${diary.latitude!.toStringAsFixed(4)}, ${diary.longitude!.toStringAsFixed(4)}',
        );
      }
    } else {
      _recordedAt = DateTime.now();
      final seed = widget.initialContent;
      if (seed != null && seed.isNotEmpty) {
        _contentController.text = seed;
      }
      _loadDraftIfAny();
    }

    _contentController.addListener(_onTextChanged);
    DiaryStationeryService.instance.addListener(_onStationeryChanged);
    unawaited(LocationService.instance.warmUp());

    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _saveScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeOutBack),
    );
    _saveOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeOut),
    );

    _initialSnapshot = _captureSnapshot();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.isEditing && widget.initialContent?.isNotEmpty != true) {
        await _loadDraftIfAny();
        if (mounted) {
          setState(() => _recordedAt = DateTime.now());
          _initialSnapshot = _captureSnapshot();
        }
      } else if (mounted) {
        _initialSnapshot = _captureSnapshot();
      }
      if (mounted) _contentFocusNode.requestFocus();
    });
  }

  _WriteSnapshot _captureSnapshot() => _WriteSnapshot(
        content: _contentController.text,
        moodWeather: _selectedWeather,
        images: List<String>.from(_imagePaths),
        recordedAt: _recordedAt,
      );

  bool get _hasUnsavedChanges {
    final current = _captureSnapshot();
    return current.content != _initialSnapshot.content ||
        current.moodWeather != _initialSnapshot.moodWeather ||
        !listEquals(current.images, _initialSnapshot.images) ||
        current.recordedAt != _initialSnapshot.recordedAt;
  }

  Future<void> _loadDraftIfAny() async {
    if (widget.isEditing || widget.initialContent?.isNotEmpty == true) return;

    final draft = await DiaryDraftService.instance.load();
    if (!mounted || draft == null) return;
    if (draft.draftId != _draftId && _contentController.text.isNotEmpty) {
      return;
    }

    setState(() {
      if (_contentController.text.isEmpty) {
        _contentController.text = draft.content;
      }
      _selectedWeather ??= draft.moodWeather;
      if (_imagePaths.isEmpty) _imagePaths.addAll(draft.imagePaths);
    });
  }

  void _scheduleDraftSave() {
    if (widget.isEditing) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  Future<void> _persistDraft() async {
    if (widget.isEditing) return;
    final text = _contentController.text;
    if (text.trim().isEmpty && _imagePaths.isEmpty && _selectedWeather == null) {
      await DiaryDraftService.instance.clear();
      return;
    }
    await DiaryDraftService.instance.save(
      draftId: _draftId,
      content: text,
      moodWeather: _selectedWeather,
      imagePaths: List<String>.from(_imagePaths),
      recordedAt: _recordedAt,
      fromEmotionalEntry: widget.fromEmotionalEntry,
    );
  }

  bool get _isWriting => _contentFocusNode.hasFocus;

  void _onTextChanged() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), _refreshPreview);
    _scheduleDraftSave();
  }

  void _refreshPreview() {
    if (!mounted) return;

    final text = _contentController.text.trim();
    if (text.isEmpty) {
      if (_previewSummary == null && _previewKeywords.isEmpty) return;
      setState(() {
        _previewSummary = null;
        _previewKeywords = [];
      });
      return;
    }

    final ai = MockAiService.instance.analyze(
      text,
      seed: _draftId,
      hasImages: _imagePaths.isNotEmpty,
    );
    if (ai.summary == _previewSummary &&
        listEquals(ai.keywords, _previewKeywords)) {
      return;
    }

    setState(() {
      _previewKeywords = ai.keywords;
      _previewSummary = ai.summary;
    });
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inset = MediaQuery.viewInsetsOf(context).bottom;
      if (inset > _lastKeyboardInset && inset > 0 && _pageScrollController.hasClients) {
        _pageScrollController.jumpTo(0);
      }
      _lastKeyboardInset = inset;
    });
  }

  /// 键盘弹出时拉高正文占位，首屏只见写作；附加项在同页下方，上滑可见。
  int _writingMinLines(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset <= 0) return 14;

    final media = MediaQuery.of(context);
    const headerH = 48.0;
    const chromeH = 88.0;
    const lineHeight = 18.0 * 1.75;
    /// 多留一截，避免键盘首屏露出「添加照片」等附加项。
    const extrasGuard = 56.0;
    final available = media.size.height -
        media.padding.top -
        media.padding.bottom -
        inset -
        headerH -
        chromeH -
        extrasGuard -
        24;
    return (available / lineHeight).floor().clamp(12, 48);
  }

  void _onStationeryChanged() => setState(() {});

  Future<void> _openStationeryPicker() async {
    FocusScope.of(context).unfocus();
    await showDiaryStationeryPicker(context);
  }

  @override
  void dispose() {
    DiaryStationeryService.instance.removeListener(_onStationeryChanged);
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    _draftTimer?.cancel();
    _saveAnimController.dispose();
    if (!widget.isEditing && !_suppressDraftPersist) _persistDraft();
    _contentController.removeListener(_onTextChanged);
    _contentFocusNode.dispose();
    _contentController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.fromEmotionalEntry && !_isWriting && !widget.isEditing) {
      return EchoColors.homeBackground;
    }
    return EchoColors.appBackground;
  }

  DiaryWriteChrome get _writeChrome =>
      DiaryWriteChrome.forStationery(DiaryStationeryService.instance.current);

  Color get _textColor {
    final stationery = DiaryStationeryService.instance.current;
    if (stationery.lightForeground) return _writeChrome.textPrimary;
    if (widget.fromEmotionalEntry && !_isWriting && !widget.isEditing) {
      return EchoColors.usesDualTone
          ? EchoColors.nightTextPrimary
          : EchoColors.dayTextPrimary;
    }
    return EchoColors.dayTextPrimary;
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_imagePaths.length >= _maxImages) return;

    List<XFile> files = [];
    if (source == ImageSource.camera) {
      final shot = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (shot != null) files = [shot];
    } else {
      files = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
    }

    if (files.isEmpty) return;

    final remaining = _maxImages - _imagePaths.length;
    if (remaining <= 0) return;

    final added = await DiaryImageStorage.instance.persistImages(
      files.take(remaining).toList(),
      _draftId,
      _imagePaths,
    );

    setState(() => _imagePaths
      ..clear()
      ..addAll(added.take(_maxImages)));
    _scheduleDraftSave();
  }

  Future<void> _showImageSourceSheet() async {
    if (_imagePaths.length >= _maxImages) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: EchoColors.daySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ScaleTap(
              onTap: () => Navigator.pop(context, ImageSource.gallery),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '从相册选择',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0EDE8)),
            ScaleTap(
              onTap: () => Navigator.pop(context, ImageSource.camera),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '拍照',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImages(source);
      if (mounted && !_contentFocusNode.hasFocus) {
        _contentFocusNode.requestFocus();
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final path = _imagePaths.removeAt(index);
      File(path).delete().ignore();
    });
    _scheduleDraftSave();
  }

  Future<void> _pickRecordedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: EchoColors.dayTextPrimary,
            onPrimary: EchoColors.daySurface,
            surface: EchoColors.daySurface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _recordedAt = DateTime(
          date.year,
          date.month,
          date.day,
          _recordedAt.hour,
          _recordedAt.minute,
        );
      });
      _scheduleDraftSave();
      if (mounted) _contentFocusNode.requestFocus();
    }
  }

  Future<void> _pickRecordedTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: EchoColors.dayTextPrimary,
            onPrimary: EchoColors.daySurface,
            surface: EchoColors.daySurface,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _recordedAt = DateTime(
          _recordedAt.year,
          _recordedAt.month,
          _recordedAt.day,
          time.hour,
          time.minute,
        );
      });
      _scheduleDraftSave();
      if (mounted) _contentFocusNode.requestFocus();
    }
  }

  Future<void> _attachLocation() async {
    final cached = await LocationService.instance.resolveCachedPlace();
    if (!mounted) return;
    if (cached != null) {
      setState(() => _location = cached);
      _scheduleDraftSave();
      if (cached.approximate) {
        unawaited(_refineLocationQuietly());
      }
      return;
    }

    setState(() => _locationLoading = true);
    final result = await LocationService.instance.resolveCurrentPlace();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _locationLoading = false;
        _location = result.location;
      });
      _scheduleDraftSave();
      return;
    }

    setState(() => _locationLoading = false);
    final message = result.userMessage;
    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w300),
        ),
        behavior: SnackBarBehavior.floating,
        action: result.failure == LocationFailure.permissionDeniedForever ||
                result.failure == LocationFailure.serviceDisabled
            ? SnackBarAction(
                label: '去设置',
                onPressed: () {
                  if (result.failure == LocationFailure.serviceDisabled) {
                    LocationService.instance.openLocationSettings();
                  } else {
                    LocationService.instance.openPermissionSettings();
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<void> _refineLocationQuietly() async {
    final result = await LocationService.instance.resolveCurrentPlace(
      preferFresh: true,
    );
    if (!mounted || !result.isSuccess) return;
    setState(() => _location = result.location);
    _scheduleDraftSave();
  }

  void _clearLocation() {
    setState(() => _location = null);
    _scheduleDraftSave();
  }

  String _formatRecordedAt() => DiaryFormat.dateLine(_recordedAt);

  Future<void> _playSaveSuccessAnimation() async {
    setState(() => _showSaveSuccess = true);
    await _saveAnimController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (mounted) {
      setState(() => _showSaveSuccess = false);
      _saveAnimController.reset();
    }
  }

  Future<bool> _save() async {
    if (_saving) return false;
    FocusScope.of(context).unfocus();

    final content = _contentController.text.trim();
    if (content.isEmpty && _imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '写点文字，或添加一张照片',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: EchoColors.nightSurface,
        ),
      );
      return false;
    }

    _draftTimer?.cancel();
    setState(() => _saving = true);

    final service = DiaryService.instance;
    final savedId = widget.editingDiary?.id ?? _draftId;
    final moodWeather = WeatherMood.resolveDisplay(_selectedWeather);
    if (_selectedWeather == null && mounted) {
      setState(() => _selectedWeather = moodWeather);
    }

    try {
      if (widget.editingDiary != null) {
        final original =
            service.getDiaryById(widget.editingDiary!.id) ?? widget.editingDiary!;
        final removed = original.images
            .where((path) => path.isNotEmpty && !_imagePaths.contains(path))
            .toList();
        await DiaryImageStorage.instance.deleteImages(removed);

        await service.save(
          id: original.id,
          content: content,
          moodWeather: moodWeather,
          imagePaths: _imagePaths,
          createdAt: _recordedAt,
          latitude: _location?.latitude,
          longitude: _location?.longitude,
          placeLabel: _location?.placeLabel,
          clearLocation: _location == null,
        );
      } else {
        await service.save(
          id: _draftId,
          content: content,
          moodWeather: moodWeather,
          imagePaths: _imagePaths,
          createdAt: _recordedAt,
          latitude: _location?.latitude,
          longitude: _location?.longitude,
          placeLabel: _location?.placeLabel,
          clearLocation: _location == null,
        );
      }

      await DiaryDraftService.instance.clear();
      _suppressDraftPersist = true;
      _initialSnapshot = _captureSnapshot();

      if (!mounted) return false;
      setState(() => _saving = false);
      await _playSaveSuccessAnimation();
      if (!mounted) return false;
      Navigator.pop(context, savedId);
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WriteDiaryPage._save failed: $e\n$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存失败，请稍后再试',
              style: TextStyle(fontWeight: FontWeight.w300),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: EchoColors.nightSurface,
          ),
        );
      }
      return false;
    } finally {
      if (mounted && _saving) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_hasUnsavedChanges) return true;

    final action = await showEchoActionSheet<String>(
      context: context,
      message: DiaryCopy.leaveConfirmMessage,
      actions: const [
        EchoActionSheetItem(label: '保存并离开', value: 'save'),
        EchoActionSheetItem(
          label: '离开',
          value: 'leave',
          isDestructive: true,
        ),
      ],
    );

    if (action == 'save') {
      return _save();
    }
    if (action == 'leave') return true;
    return false;
  }

  Future<void> _close() async {
    FocusScope.of(context).unfocus();
    final leave = await _confirmLeave();
    if (leave && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final stationery = DiaryStationeryService.instance.current;
    final useStationery = stationery.hasImage;
    final media = MediaQuery.of(context);
    final scrollMinHeight = media.size.height -
        media.padding.top -
        media.padding.bottom -
        (keyboardOpen ? 136.0 : 88.0) -
        48.0;
    final chromeBackground =
        useStationery ? stationery.scrollSurfaceColor : _backgroundColor;
    final writeChrome = DiaryWriteChrome.forStationery(stationery);
    final contentPanelColor = stationery.contentPanelColor;
    final horizontalPad = contentPanelColor != null ? 14.0 : 24.0;

    Widget buildContentColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                key: const ValueKey('echo_diary_content'),
                controller: _contentController,
                focusNode: _contentFocusNode,
                minLines: _writingMinLines(context),
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollPadding: const EdgeInsets.all(24),
                cursorColor: writeChrome.textPrimary,
                style: writeChrome.textStyle(
                  color: writeChrome.textPrimary,
                  fontSize: 18,
                  height: 1.75,
                  letterSpacing: 0.15,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4, bottom: 12),
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          if (keyboardOpen) const SizedBox(height: 80),
          _ExtrasSection(
            chrome: writeChrome,
            imagePaths: _imagePaths,
            maxImages: _maxImages,
            selectedWeather: _selectedWeather,
            previewSummary: _previewSummary,
            previewKeywords: _previewKeywords,
            onRemoveImage: _removeImage,
            onPickImages: _showImageSourceSheet,
            recordedAtLabel: _formatRecordedAt(),
            recordedTimeLabel:
                '${_recordedAt.hour.toString().padLeft(2, '0')}:${_recordedAt.minute.toString().padLeft(2, '0')}',
            onPickRecordedDate: _pickRecordedDate,
            onPickRecordedTime: _pickRecordedTime,
            placeLabel: _location?.placeLabel,
            placeApproximate: _location?.approximate ?? false,
            locationLoading: _locationLoading,
            onAttachLocation: _attachLocation,
            onClearLocation: _clearLocation,
            onWeatherSelected: (mood) {
              setState(() {
                _selectedWeather = _selectedWeather == mood ? null : mood;
              });
              _scheduleDraftSave();
            },
          ),
          SizedBox(height: keyboardOpen ? 8 : 72),
        ],
      );
    }

    var contentColumn = buildContentColumn();
    if (contentPanelColor != null) {
      contentColumn = DecoratedBox(
        decoration: BoxDecoration(
          color: contentPanelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: contentColumn,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: ColoredBox(
        color: useStationery ? stationery.scrollSurfaceColor : _backgroundColor,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              if (useStationery)
                Positioned.fill(
                  child: DiaryStationeryBackdrop(stationery: stationery),
                ),
              SafeArea(
                top: !useStationery,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: useStationery ? media.padding.top : 0,
                          ),
                          child: _buildHeader(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _pageScrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    scrollMinHeight.clamp(0, double.infinity),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPad,
                                  4,
                                  horizontalPad,
                                  keyboardOpen ? 16 : 24,
                                ),
                                child: contentColumn,
                              ),
                            ),
                          ),
                        ),
                        if (keyboardOpen) ...[
                          _ScrollHint(
                            backgroundColor: chromeBackground,
                            chrome: writeChrome,
                          ),
                          _KeyboardToolbar(
                            backgroundColor: chromeBackground,
                            chrome: writeChrome,
                            saving: _saving,
                            onSave: _save,
                          ),
                        ] else
                          _BottomBar(
                            backgroundColor: chromeBackground,
                            chrome: writeChrome,
                            saving: _saving,
                            onSave: _save,
                          ),
                      ],
                    ),
                    if (_showSaveSuccess)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: chromeBackground.withValues(alpha: 0.92),
                            child: FadeTransition(
                              opacity: _saveOpacity,
                              child: Center(
                                child: ScaleTransition(
                                  scale: _saveScale,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: EchoColors.todoCompletedSurface,
                                          border: Border.all(
                                            color: EchoColors.todoCompletedBorder,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 28,
                                          color: EchoColors.todoCompletedFill,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        DiaryCopy.savedSnack,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w300,
                                          color: _textColor,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final chrome = _writeChrome;
    final iconColor = chrome.effectiveIconColor;
    final iconBg = chrome.textPrimary.withValues(alpha: 0.1);
    final iconBorder = chrome.textPrimary.withValues(alpha: 0.14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          ScaleTap(
            onTap: _close,
            scale: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.close, size: 22, color: iconColor),
            ),
          ),
          const Spacer(),
          ScaleTap(
            onTap: _openStationeryPicker,
            scale: 0.92,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconBorder, width: 0.5),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 20,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtrasSection extends StatelessWidget {
  const _ExtrasSection({
    required this.chrome,
    required this.imagePaths,
    required this.maxImages,
    required this.selectedWeather,
    required this.previewSummary,
    required this.previewKeywords,
    required this.recordedAtLabel,
    required this.recordedTimeLabel,
    required this.onRemoveImage,
    required this.onPickImages,
    required this.onPickRecordedDate,
    required this.onPickRecordedTime,
    required this.onWeatherSelected,
    this.placeLabel,
    this.placeApproximate = false,
    this.locationLoading = false,
    this.onAttachLocation,
    this.onClearLocation,
  });

  final DiaryWriteChrome chrome;
  final List<String> imagePaths;
  final int maxImages;
  final String? selectedWeather;
  final String? previewSummary;
  final List<String> previewKeywords;
  final String recordedAtLabel;
  final String recordedTimeLabel;
  final void Function(int index) onRemoveImage;
  final VoidCallback onPickImages;
  final VoidCallback onPickRecordedDate;
  final VoidCallback onPickRecordedTime;
  final void Function(String mood) onWeatherSelected;
  final String? placeLabel;
  final bool placeApproximate;
  final bool locationLoading;
  final VoidCallback? onAttachLocation;
  final VoidCallback? onClearLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagePaths.isNotEmpty) ...[
          _ImageGrid(paths: imagePaths, onRemove: onRemoveImage),
          const SizedBox(height: 12),
        ],
        if (imagePaths.length < maxImages)
          ScaleTap(
            onTap: onPickImages,
            scale: 0.98,
            child: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 20,
                  color: chrome.effectiveIconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '添加照片（${imagePaths.length}/$maxImages）',
                  style: chrome.textStyle(color: chrome.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text(
          DiaryCopy.recordedTime,
          style: chrome.textStyle(color: chrome.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ScaleTap(
          onTap: onPickRecordedDate,
          scale: 0.98,
          child: _RecordedRow(
            label: '日期',
            value: recordedAtLabel,
            chrome: chrome,
          ),
        ),
        const SizedBox(height: 8),
        ScaleTap(
          onTap: onPickRecordedTime,
          scale: 0.98,
          child: _RecordedRow(
            label: '时间',
            value: recordedTimeLabel,
            chrome: chrome,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '位置',
          style: chrome.textStyle(color: chrome.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (placeLabel != null && placeLabel!.trim().isNotEmpty)
          ScaleTap(
            onTap: onClearLocation,
            scale: 0.98,
            child: _RecordedRow(
              label: '地点',
              value: placeApproximate ? '${placeLabel!}（约）' : placeLabel!,
              chrome: chrome,
            ),
          )
        else
          ScaleTap(
            onTap: locationLoading ? () {} : (onAttachLocation ?? () {}),
            scale: 0.98,
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: chrome.effectiveIconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  locationLoading ? '获取位置中…' : '添加当前位置',
                  style: chrome.textStyle(color: chrome.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text(
          '天象心情',
          style: chrome.textStyle(color: chrome.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WeatherMood.options.map((mood) {
            final selected = selectedWeather == mood.display;
            return ScaleTap(
              onTap: () => onWeatherSelected(mood.display),
              scale: 0.96,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                child: Text(
                  mood.display,
                  style: chrome.textStyle(
                    color: selected
                        ? chrome.textPrimary
                        : chrome.textSecondary,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (previewSummary != null && previewSummary!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Divider(
            height: 24,
            thickness: 0.5,
            color: chrome.divider,
          ),
          Text(
            'Echo 轻读',
            style: chrome.textStyle(color: chrome.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            previewSummary!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: chrome.textStyle(
              color: chrome.textPrimary,
              height: 1.6,
            ),
          ),
          if (previewKeywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: previewKeywords.take(4).map(
                (k) => Text(
                  k,
                  style: chrome.textStyle(
                    color: chrome.textWhisper,
                    fontSize: 12,
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RecordedRow extends StatelessWidget {
  const _RecordedRow({
    required this.label,
    required this.value,
    required this.chrome,
  });

  final String label;
  final String value;
  final DiaryWriteChrome chrome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: chrome.textStyle(color: chrome.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: chrome.textStyle(
              color: chrome.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({
    required this.backgroundColor,
    required this.chrome,
  });

  final Color backgroundColor;
  final DiaryWriteChrome chrome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox(
        height: 36,
        child: Center(
          child: Text(
            '向上滑动可添加照片、日期与位置',
            style: chrome.textStyle(
              color: chrome.textSecondary.withValues(alpha: 0.9),
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardToolbar extends StatelessWidget {
  const _KeyboardToolbar({
    required this.backgroundColor,
    required this.chrome,
    required this.saving,
    required this.onSave,
  });

  final Color backgroundColor;
  final DiaryWriteChrome chrome;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: chrome.toolbarBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ScaleTap(
              onTap: saving ? () {} : onSave,
              scale: 0.96,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: chrome.saveFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  saving ? '保存中' : '完成',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: chrome.saveLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.backgroundColor,
    required this.chrome,
    required this.saving,
    required this.onSave,
  });

  final Color backgroundColor;
  final DiaryWriteChrome chrome;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: chrome.toolbarBorder,
            width: 0.5,
          ),
        ),
      ),
      child: ScaleTap(
        onTap: saving ? () {} : onSave,
        scale: 0.98,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: chrome.saveFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            saving ? '保存中' : '完成',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: chrome.saveLabel,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.paths,
    required this.onRemove,
  });

  final List<String> paths;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (paths.length == 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (width * 0.72).clamp(160.0, 280.0);
          return _ImageTile(
            path: paths.first,
            width: width,
            height: height,
            onRemove: () => onRemove(0),
          );
        },
      );
    }

    final columns = paths.length == 2 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paths.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return _ImageTile(
          path: paths[index],
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.path,
    required this.onRemove,
    this.width,
    this.height,
  });

  final String path;
  final VoidCallback onRemove;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: ScaleTap(
              onTap: onRemove,
              scale: 0.9,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
