import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'repositories/support_repository.dart';

/// Contact Support: order card, segment (USA/Turkey/Entire), issue grid, details, attachments, submit.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key, this.initialOrderId});

  final String? initialOrderId;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final SupportRepository _repo = SupportRepository();
  final TextEditingController _detailsController = TextEditingController();
  int _segmentIndex = 0;
  int _selectedIssueIndex = 0;
  final List<String> _attachmentPaths = [];
  bool _submitting = false;

  static const List<Map<String, dynamic>> _issues = [
    {'label': 'Damaged Item', 'icon': Icons.inventory_2_outlined},
    {'label': 'Shipping delay', 'icon': Icons.schedule_outlined},
    {'label': 'Customs issue', 'icon': Icons.gavel_outlined},
    {'label': 'Missing item', 'icon': Icons.remove_shopping_cart_outlined},
  ];

  static const int _maxAttachments = 5;
  static const int _maxDetailsLength = 500;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final ticketId = await _repo.submitSupportRequest(
        orderId: widget.initialOrderId ?? 'ZY-9901',
        issueType: _issues[_selectedIssueIndex]['label'] as String,
        details: _detailsController.text.trim(),
        attachmentPaths: _attachmentPaths.isEmpty ? null : _attachmentPaths,
      );
      if (mounted) {
        context.push('${AppRoutes.supportSuccess}?ticketId=${Uri.encodeComponent(ticketId)}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Contact Support'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _OrderCard(orderId: widget.initialOrderId ?? 'ZY-9901'),
              const SizedBox(height: AppSpacing.lg),
              Text('Select order part', style: AppTextStyles.label(AppConfig.subtitleColor)),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('USA')),
                  ButtonSegment(value: 1, label: Text('Turkey')),
                  ButtonSegment(value: 2, label: Text('Entire Order')),
                ],
                selected: {_segmentIndex},
                onSelectionChanged: (s) => setState(() => _segmentIndex = s.first),
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  )),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select the issue', style: AppTextStyles.titleMedium(AppConfig.textColor)),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.4,
                children: List.generate(_issues.length, (i) {
                  final issue = _issues[i];
                  final selected = _selectedIssueIndex == i;
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIssueIndex = i),
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? AppConfig.primaryColor : AppConfig.borderColor,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              issue['icon'] as IconData,
                              size: 28,
                              color: selected ? AppConfig.primaryColor : AppConfig.subtitleColor,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              issue['label'] as String,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall(
                                selected ? AppConfig.primaryColor : AppConfig.subtitleColor,
                              ),
                            ),
                            if (selected)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.check_circle, color: AppConfig.primaryColor, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Details', style: AppTextStyles.label(AppConfig.subtitleColor)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                maxLength: _maxDetailsLength,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Describe your issue...',
                  hintStyle: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    borderSide: const BorderSide(color: AppConfig.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    borderSide: const BorderSide(color: AppConfig.borderColor),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              Text(
                '${_detailsController.text.length}/$_maxDetailsLength',
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Please be as specific as possible',
                  style: AppTextStyles.bodySmall(AppConfig.primaryColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Attachments', style: AppTextStyles.label(AppConfig.subtitleColor)),
              Text(
                'Supported files: JPG, PNG, PDF – Max $_maxAttachments files',
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ..._attachmentPaths.asMap().entries.map((e) {
                    return Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppConfig.borderColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                          ),
                          child: const Center(child: Icon(Icons.insert_drive_file)),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _attachmentPaths.removeAt(e.key)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: AppConfig.errorRed,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_attachmentPaths.length < _maxAttachments)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_attachmentPaths.length < _maxAttachments) {
                            _attachmentPaths.add('mock_path_${_attachmentPaths.length}');
                          }
                        });
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppConfig.borderColor),
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Support Request'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        border: Border.all(color: AppConfig.borderColor),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppConfig.subtitleColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderId', style: AppTextStyles.titleMedium(AppConfig.textColor)),
                Text(
                  'In Transit: Istanbul Hub',
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
