import 'dart:io';

import 'package:flutter/material.dart';

/// 첫 로그인 시 표시되는 환영 다이얼로그
/// pencil 노드 jSspO 디자인 기반
class GuideDialog extends StatelessWidget {
  const GuideDialog({super.key});

  /// 환영 다이얼로그 표시
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFDFDF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 그룹
            // 아이콘 컨테이너
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFA8DAB5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 28,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            // 타이틀
            const Text(
              '환영합니다!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C19),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 서브타이틀
            const Text(
              '우리의 생활 공유 가계부',
              style: TextStyle(fontSize: 14, color: Color(0xFF44483E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 구분선
            const Divider(color: Color(0xFFC4C8BB), height: 1),
            const SizedBox(height: 20),
            // 본문 그룹
            const Text(
              '함께하는 가계부 관리!\n설정에서 가이드를 확인하고\n시작하는 방법을 알아보세요.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF44483E),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Tip 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFA8DAB5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '설정 > 정보 > 가이드',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
            // 알림 안내 박스 (Android 전용)
            if (Platform.isAndroid) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: Color(0xFFE65100),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '알림 권한을 모두 허용해야 자동수집 등\n모든 기능을 원활하게 사용할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBF360C),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
