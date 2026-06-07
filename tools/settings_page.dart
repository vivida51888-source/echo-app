import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../services/echo_appearance_service.dart';
import '../utils/future_letter_copy.dart';
import '../theme/echo_colors.dart';
import '../widgets/echo_hub_tile.dart';
import '../widgets/echo_page_header.dart';
import 'appearance_page.dart';
import 'future_letters_page.dart';
import 'important_days_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EchoColors.appBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EchoPageHeader(
              title: '设置',
              subtitle: 'Echo · 回响',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const EchoSectionLabel('时间 · 记忆'),
                  EchoHubTile(
                    title: FutureLetterCopy.settingsTitle,
                    subtitle: FutureLetterCopy.settingsSubtitle,
                    icon: Icons.mail_outline_rounded,
                    iconTint: const Color(0xFF8A7AA8),
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute<void>(
                          builder: (_) => const FutureLettersPage(),
                        ),
                      );
                    },
                  ),
                  EchoHubTile(
                    title: '印记 · 重要日',
                    subtitle: '生日、纪念日… Echo 会轻轻记得',
                    icon: Icons.event_outlined,
                    iconTint: const Color(0xFF9AB898),
                    onTap: () {
                      Navigator.of(context).push(
                        AppPageRoute<void>(
                          builder: (_) => const ImportantDaysPage(),
                        ),
                      );
                    },
                  ),
                  const EchoSectionLabel('Echo'),
                  EchoHubTile(
                    title: '关于 Echo',
                    subtitle: '安静地记录，未来为你回响',
                    icon: Icons.favorite_outline_rounded,
                    iconTint: const Color(0xFF8B7355),
                    onTap: () {},
                  ),
                  EchoHubTile(
                    title: '待办 · AI 洞察',
                    subtitle: '周报可引用完成情况；可在未来关闭',
                    icon: Icons.insights_outlined,
                    iconTint: const Color(0xFF7A8FA8),
                    onTap: () {},
                  ),
                  const EchoSectionLabel('偏好'),
                  EchoHubTile(
                    title: '数据与隐私',
                    icon: Icons.shield_outlined,
                    iconTint: EchoColors.dayTextSecondary,
                    onTap: () {},
                  ),
                  ListenableBuilder(
                    listenable: EchoAppearanceService.instance,
                    builder: (context, _) {
                      final name = EchoAppearanceService.instance.presetName;
                      return EchoHubTile(
                        title: '外观',
                        subtitle: '纸色 · 当前$name',
                        icon: Icons.palette_outlined,
                        iconTint: EchoColors.dayTextSecondary,
                        onTap: () => openAppearancePage(context),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
