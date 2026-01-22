import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/learned_sms_format.dart';
import '../../domain/entities/financial_service_template.dart';
import '../../data/services/sms_parsing_service.dart';
import '../../data/services/sms_listener_service.dart';
import '../../data/services/sms_scanner_service.dart';
import '../providers/payment_method_provider.dart';

class PaymentMethodWizardPage extends ConsumerStatefulWidget {
  final PaymentMethod? paymentMethod;
  const PaymentMethodWizardPage({super.key, this.paymentMethod});

  @override
  ConsumerState<PaymentMethodWizardPage> createState() =>
      _PaymentMethodWizardPageState();
}

class _PaymentMethodWizardPageState
    extends ConsumerState<PaymentMethodWizardPage> {
  late int _currentStep;
  FinancialServiceTemplate? _selectedTemplate;
  late TextEditingController _nameController;
  late TextEditingController _sampleController;

  bool get isEdit => widget.paymentMethod != null;

  // 알림 타입 선택 (sms | push)
  String _notificationType = 'sms';

  // 분석된 포맷
  LearnedSmsFormat? _generatedFormat;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.paymentMethod?.name ?? '',
    );
    _sampleController = TextEditingController();

    // 수정 모드인 경우 초기 설정
    if (isEdit) {
      _currentStep = 1;
      // 템플릿 매칭 시도 (이름 기반)
      _selectedTemplate = FinancialServiceTemplate.templates
          .cast<FinancialServiceTemplate?>()
          .firstWhere(
            (t) => t?.name == widget.paymentMethod?.name,
            orElse: () => null,
          );

      if (_selectedTemplate != null) {
        _sampleController.text = _selectedTemplate!.defaultSampleSms;
      }
    } else {
      _currentStep = 0;
    }

    // 샘플 텍스트 변경 시 포맷 재분석
    _sampleController.addListener(_analyzeSample);

    // 초기 분석 실행
    if (_sampleController.text.isNotEmpty) {
      _analyzeSample();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sampleController.dispose();
    super.dispose();
  }

  void _analyzeSample() {
    if (_selectedTemplate == null) return;

    final sample = _sampleController.text;
    if (sample.isEmpty) return;

    setState(() {
      _generatedFormat = SmsParsingService.generateFormatFromSample(
        sample: sample,
        paymentMethodId: widget.paymentMethod?.id ?? 'temp_id',
      );
    });
  }

  void _selectTemplate(FinancialServiceTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _currentStep = 1;

      if (template != null) {
        _nameController.text = template.name;
        _notificationType = 'sms'; // 기본값
        _sampleController.text = template.defaultSampleSms;
        _analyzeSample();
      } else {
        // 직접 입력 (수동)
        _nameController.text = '';
        _sampleController.text = '';
        _generatedFormat = null;
      }
    });
  }

  void _changeNotificationType(String type) {
    if (_selectedTemplate == null) return;

    setState(() {
      _notificationType = type;
      if (type == 'sms') {
        _sampleController.text = _selectedTemplate!.defaultSampleSms;
      } else {
        _sampleController.text =
            _selectedTemplate!.defaultSamplePush ??
            _selectedTemplate!.defaultSampleSms;
      }
      _analyzeSample();
    });
  }

  void _goBack() {
    if (_currentStep > 0 && !isEdit) {
      setState(() {
        if (_currentStep == 1) {
          _selectedTemplate = null;
        }
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    // 직접 입력의 경우 _generatedFormat이 null일 수 있음
    if (_selectedTemplate != null && _generatedFormat == null) return;

    try {
      final notifier = ref.read(paymentMethodNotifierProvider.notifier);

      if (isEdit) {
        // 1. 결제수단 수정
        await notifier.updatePaymentMethod(
          id: widget.paymentMethod!.id,
          name: _nameController.text,
          canAutoSave: _selectedTemplate != null,
        );

        // 2. 학습된 포맷 저장 (템플릿 선택 시에만)
        if (_selectedTemplate != null && _generatedFormat != null) {
          // TODO: Repository를 통해 포맷 저장 로직 연결
          print(
            'Updated Format for ${widget.paymentMethod!.id}: $_generatedFormat',
          );
        }
      } else {
        // 1. 결제수단 생성
        final paymentMethodId = await notifier.createPaymentMethod(
          name: _nameController.text,
          icon: '',
          color: _selectedTemplate?.color ?? '#9E9E9E', // 템플릿 없으면 회색
          canAutoSave: _selectedTemplate != null, // 템플릿이 있을 때만 자동수집 가능
        );

        // 2. 학습된 포맷 저장 (템플릿 선택 시에만)
        if (_selectedTemplate != null && _generatedFormat != null) {
          // TODO: Repository를 통해 포맷 저장 로직 연결
          print('Saved Format for $paymentMethodId: $_generatedFormat');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '결제수단 수정' : '결제수단 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: _currentStep == 0
          ? _buildServiceSelection()
          : _buildConfiguration(),
    );
  }

  Widget _buildServiceSelection() {
    final cards = FinancialServiceTemplate.templates
        .where((t) => t.category == FinancialServiceCategory.card)
        .toList();
    final localCurrencies = FinancialServiceTemplate.templates
        .where((t) => t.category == FinancialServiceCategory.localCurrency)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '어떤 서비스를 이용하시나요?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // 1. 카드 섹션
        if (cards.isNotEmpty) ...[
          const Text('카드', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          ...cards.map((t) => _buildTemplateTile(t)),
          const SizedBox(height: 24),
        ],

        // 2. 지역화폐 섹션
        if (localCurrencies.isNotEmpty) ...[
          const Text(
            '지역화폐',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...localCurrencies.map((t) => _buildTemplateTile(t)),
          const SizedBox(height: 24),
        ],

        // 3. 직접 입력 섹션
        const Text('기타', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.edit, color: Colors.white),
            ),
            title: const Text('직접 입력'),
            subtitle: const Text('자동 수집 기능 없이 결제수단만 추가합니다.'),
            onTap: () => _selectTemplate(null), // null = 직접 입력
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateTile(FinancialServiceTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _safeParseColor(template.color),
          child: Text(
            template.name.isNotEmpty ? template.name[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(template.name),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _selectTemplate(template),
      ),
    );
  }

  Widget _buildConfiguration() {
    // 직접 입력인 경우 (템플릿 없음) -> 단순 이름 입력 및 저장
    if (_selectedTemplate == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '결제수단 이름',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              maxLength: 20,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 신한카드',
                counterText: '',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) _submit();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('저장하기'),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 이름 설정
          TextFormField(
            controller: _nameController,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: '별칭',
              helperText: '앱 내에서 표시될 이름입니다.',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),

          // 2. 샘플 에디터 (수집 설정)
          const Text(
            '자동 수집 규칙 설정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40, // 행의 높이를 고정하여 UI 흔들림 방지
            child: Row(
              children: [
                Expanded(
                  child: Visibility(
                    visible: _notificationType == 'sms',
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton.icon(
                      onPressed: _showSmsImportDialog,
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('문자에서 가져오기'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
                // SMS / Push 토글
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'sms', label: Text('SMS')),
                    ButtonSegment(value: 'push', label: Text('Push')),
                  ],
                  selected: {_notificationType},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeNotificationType(newSelection.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '아래 메시지는 예시입니다. 실제로 받으시는 알림과 다르다면 수정해주세요.\n수정한 내용에 맞춰 수집 규칙이 변경됩니다.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _sampleController,
            readOnly: true, // 읽기 전용으로 변경
            maxLines: 5,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),

          const SizedBox(height: 24),

          // 3. 분석 결과 미리보기 (규칙)
          if (_generatedFormat != null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '현재 규칙으로 수집되는 정보',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildRuleRow(
                      '감지 키워드 (OR 조건)',
                      _generatedFormat!.senderKeywords.join(', '),
                    ),
                    _buildRuleRow(
                      '금액 패턴 (필수)',
                      _getFriendlyAmountPattern(_generatedFormat!.amountRegex),
                    ),
                    // 실제 파싱 결과 시뮬레이션 표시도 가능
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getFriendlyAmountPattern(String regex) {
    // 기본 패턴: r'([0-9,]+)\s*원'
    if (regex.contains('원') && regex.contains('[0-9,]+')) {
      return '\'원\' 앞의 숫자';
    }
    // 다른 패턴들에 대한 대응 추가 가능
    return regex; // 알 수 없는 경우 그대로 표시
  }

  Future<void> _showSmsImportDialog() async {
    final scanner = ref.read(smsScannerServiceProvider);

    // 권한 체크 (간소화됨)
    final hasPermission = await SmsListenerService.instance.checkPermissions();
    if (!hasPermission) {
      final granted = await SmsListenerService.instance.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('SMS 권한이 필요합니다.')));
        }
        return;
      }
    }

    if (!mounted) return;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<SmsFormatScanResult>(
              future: scanner.scanFinancialSms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data?.financialMessages ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('금융 관련 문자를 찾을 수 없습니다.'));
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '가져올 문자 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ListTile(
                            title: Text(msg.sender),
                            subtitle: Text(msg.body),
                            trailing: Text('${msg.date.month}/${msg.date.day}'),
                            onTap: () {
                              _sampleController.text = msg.body;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ); // unawaited 닫는 괄호
  }

  Color _safeParseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
