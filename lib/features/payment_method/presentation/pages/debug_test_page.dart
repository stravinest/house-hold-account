import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_household_account/features/payment_method/data/services/debug_test_service.dart';
import 'package:shared_household_account/shared/themes/design_tokens.dart';

class DebugTestPage extends ConsumerStatefulWidget {
  const DebugTestPage({super.key});

  @override
  ConsumerState<DebugTestPage> createState() => _DebugTestPageState();
}

class _DebugTestPageState extends ConsumerState<DebugTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DebugStatus? _status;
  SupabaseStatus? _supabaseStatus;
  bool _isLoading = false;
  String? _lastResult;
  int _selectedSmsTemplate = 0;
  int _selectedPushTemplate = 0;
  final _amountController = TextEditingController(text: '50000');
  final _merchantController = TextEditingController(text: '스타벅스');
  final _customContentController = TextEditingController();
  ParsedResult? _parseResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _customContentController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    if (!DebugTestService.isAvailable) return;

    setState(() => _isLoading = true);
    try {
      final status = await DebugTestService.getDebugStatus();
      final supabaseStatus = await DebugTestService.getSupabaseStatus();
      setState(() {
        _status = status;
        _supabaseStatus = supabaseStatus;
      });
    } catch (e) {
      _showError('상태 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSmsTest() async {
    setState(() => _isLoading = true);
    try {
      final template = DebugTestService.smsTemplates[_selectedSmsTemplate];
      final amount = int.tryParse(_amountController.text) ?? 50000;
      final merchant = _merchantController.text;

      final result = await DebugTestService.simulateSmsWithTemplate(
        template,
        amount: amount,
        merchant: merchant,
      );

      setState(() {
        _lastResult =
            '''
SMS 전송 완료!
- SQLite ID: ${result.sqliteId}
- Supabase 저장: ${result.supabaseSuccess ? '성공' : '실패'}
- 대기 중: ${result.pendingCount}건
''';
      });

      await _loadStatus();
    } catch (e) {
      _showError('SMS 전송 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPushTest() async {
    setState(() => _isLoading = true);
    try {
      final template = DebugTestService.pushTemplates[_selectedPushTemplate];
      final amount = int.tryParse(_amountController.text) ?? 50000;
      final merchant = _merchantController.text;

      final result = await DebugTestService.simulatePushWithTemplate(
        template,
        amount: amount,
        merchant: merchant,
      );

      setState(() {
        _lastResult =
            '''
Push 전송 완료!
- SQLite ID: ${result.sqliteId}
- Supabase 저장: ${result.supabaseSuccess ? '성공' : '실패'}
- 대기 중: ${result.pendingCount}건
''';
      });

      await _loadStatus();
    } catch (e) {
      _showError('Push 전송 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testParsing() async {
    final content = _customContentController.text;
    if (content.isEmpty) {
      _showError('내용을 입력하세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await DebugTestService.testParsing(content: content);
      setState(() => _parseResult = result);
    } catch (e) {
      _showError('파싱 테스트 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('SQLite의 모든 캐시 데이터를 삭제합니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final count = await DebugTestService.clearAllTestData();
      setState(() => _lastResult = '$count건의 데이터가 삭제되었습니다.');
      await _loadStatus();
    } catch (e) {
      _showError('데이터 삭제 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('디버그 테스트')),
        body: const Center(child: Text('디버그 모드에서만 사용 가능합니다.')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자동수집 디버그'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '상태'),
            Tab(text: 'SMS'),
            Tab(text: 'Push'),
            Tab(text: '파싱'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatusTab(colorScheme),
                _buildSmsTab(colorScheme),
                _buildPushTab(colorScheme),
                _buildParseTab(colorScheme),
              ],
            ),
    );
  }

  Widget _buildStatusTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            title: 'SQLite 상태',
            icon: Icons.storage,
            items: [
              _StatusItem(
                '대기 중',
                '${_status?.sqlitePendingCount ?? 0}건',
                (_status?.sqlitePendingCount ?? 0) > 0
                    ? colorScheme.primary
                    : null,
              ),
              _StatusItem(
                '실패',
                '${_status?.sqliteFailedCount ?? 0}건',
                (_status?.sqliteFailedCount ?? 0) > 0
                    ? colorScheme.error
                    : null,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _buildStatusCard(
            title: 'Supabase 상태',
            icon: Icons.cloud,
            items: [
              _StatusItem(
                '초기화',
                _supabaseStatus?.initialized == true ? '완료' : '미완료',
                _supabaseStatus?.initialized == true
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              _StatusItem(
                '토큰',
                _supabaseStatus?.tokenValid == true ? '유효' : '만료/없음',
                _supabaseStatus?.tokenValid == true
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              _StatusItem(
                'Refresh 토큰',
                _supabaseStatus?.hasRefreshToken == true ? '있음' : '없음',
              ),
              _StatusItem('가계부 ID', _supabaseStatus?.ledgerId ?? '없음'),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _buildStatusCard(
            title: 'NotificationListener',
            icon: Icons.notifications,
            items: [
              _StatusItem(
                '서비스 상태',
                _status?.notificationListenerActive == true ? '활성' : '비활성',
                _status?.notificationListenerActive == true
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (_lastResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '마지막 결과',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(_lastResult!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearAllData,
              icon: const Icon(Icons.delete_outline),
              label: const Text('SQLite 캐시 전체 삭제'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMS 템플릿', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: List.generate(DebugTestService.smsTemplates.length, (
              index,
            ) {
              final template = DebugTestService.smsTemplates[index];
              return ChoiceChip(
                label: Text(template.name),
                selected: _selectedSmsTemplate == index,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSmsTemplate = index);
                },
              );
            }),
          ),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '금액',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: '가맹점',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _sendSmsTest,
              icon: const Icon(Icons.sms),
              label: const Text('SMS 시뮬레이션 전송'),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('미리보기', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _getSmsPreview(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Push 템플릿', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: List.generate(DebugTestService.pushTemplates.length, (
              index,
            ) {
              final template = DebugTestService.pushTemplates[index];
              return ChoiceChip(
                label: Text(template.name),
                selected: _selectedPushTemplate == index,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedPushTemplate = index);
                },
              );
            }),
          ),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '금액',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: '가맹점',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _sendPushTest,
              icon: const Icon(Icons.notifications),
              label: const Text('Push 시뮬레이션 전송'),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('미리보기', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _getPushPreview(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParseTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('파싱 테스트', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Text(
            'SMS 또는 Push 알림 내용을 입력하여 파싱 결과를 확인합니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _customContentController,
            decoration: const InputDecoration(
              labelText: '알림 내용',
              hintText: 'KB국민카드 1234승인\n홍*동\n50,000원 일시불\n스타벅스',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _testParsing,
              icon: const Icon(Icons.psychology),
              label: const Text('파싱 테스트'),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          if (_parseResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _parseResult!.isParsed
                              ? Icons.check_circle
                              : Icons.error,
                          color: _parseResult!.isParsed
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          _parseResult!.isParsed ? '파싱 성공' : '파싱 실패',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildParseResultRow(
                      '금액',
                      '${_parseResult!.amount ?? '-'}원',
                    ),
                    _buildParseResultRow(
                      '거래 유형',
                      _parseResult!.transactionType ?? '-',
                    ),
                    _buildParseResultRow('가맹점', _parseResult!.merchant ?? '-'),
                    _buildParseResultRow(
                      '카드 끝자리',
                      _parseResult!.cardLastDigits ?? '-',
                    ),
                    _buildParseResultRow(
                      '신뢰도',
                      '${(_parseResult!.confidence * 100).toInt()}%',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParseResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required IconData icon,
    required List<_StatusItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: Spacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const Divider(),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSmsPreview() {
    final template = DebugTestService.smsTemplates[_selectedSmsTemplate];
    final amount = int.tryParse(_amountController.text) ?? 50000;
    final merchant = _merchantController.text.isEmpty
        ? '스타벅스'
        : _merchantController.text;
    return '발신자: ${template.sender}\n\n${template.bodyBuilder(amount, merchant)}';
  }

  String _getPushPreview() {
    final template = DebugTestService.pushTemplates[_selectedPushTemplate];
    final amount = int.tryParse(_amountController.text) ?? 50000;
    final merchant = _merchantController.text.isEmpty
        ? '스타벅스'
        : _merchantController.text;
    return '패키지: ${template.packageName}\n제목: ${template.title}\n\n${template.textBuilder(amount, merchant)}';
  }
}

class _StatusItem {
  final String label;
  final String value;
  final Color? color;

  _StatusItem(this.label, this.value, [this.color]);
}
