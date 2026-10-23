/// Mây Family Finance — Household Setup Screen (UI-03)
///
/// First-screen after sign-in: name, currency, timezone for the user's personal household.
/// On submit → createHousehold (F01) Cloud Function → navigate to accounts screen.
/// Per BR-02: if user already has a household, F01 returns existing — show Shell directly.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:may/features/onboarding/domain/household_repository.dart';
import 'package:may/shared/design_system/tokens/may_colors.dart';
import 'package:may/shared/design_system/tokens/may_spacing.dart';
import 'package:may/shared/design_system/tokens/may_typography.dart';
import 'package:may/shared/widgets/may_button.dart';
import 'package:may/shared/widgets/may_card.dart';
import 'package:may/shared/widgets/may_segmented_control.dart';
import 'package:may/shared/widgets/may_text.dart';

/// Household setup screen with name, currency and timezone fields.
class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _nameCtrl = TextEditingController();
  HouseholdCurrency _currency = HouseholdCurrency.vnd;
  String _timezone = 'Asia/Ho_Chi_Minh';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name.length > 50) {
      setState(() => _error = 'Tên hộ gia đình phải từ 1-50 ký tự.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await HouseholdRepository.instance.createHousehold(
        name: name,
        currency: _currency,
        timezone: _timezone,
      );
      if (mounted) context.go('/onboarding/accounts');
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Đã xảy ra lỗi khi tạo hộ gia đình.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final canvas = isLight ? MayColors.canvas : MayColors.canvasDark;

    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: canvas,
              title: MayText('Thiết lập hộ gia đình',
                  style: MayTypography.titleMedium(context)),
              centerTitle: true,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: MayColors.secondary),
                    ),
                    SizedBox(width: MaySpacing.s8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(MaySpacing.s20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Name field
                  MayCard.flat(
                    child: Padding(
                      padding: const EdgeInsets.all(MaySpacing.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MayText('Tên hộ gia đình',
                                  style: MayTypography.bodyMedium(context)),
                              SizedBox(width: MaySpacing.s4),
                              Text('*',
                                  style: TextStyle(
                                      color: MayColors.danger, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: MaySpacing.s8),
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'VD: Gia đình Minh',
                              filled: true,
                              fillColor: MayColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: MaySpacing.s16,
                                vertical: 14.0,
                              ),
                            ),
                            maxLines: null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${_nameCtrl.text.length}/50',
                                  style: TextStyle(
                                    color: _nameCtrl.text.length > 50
                                        ? MayColors.danger
                                        : MayColors.secondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MaySpacing.s16),
                  // Currency field
                  MayCard.flat(
                    child: Padding(
                      padding: const EdgeInsets.all(MaySpacing.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MayText('Tiền tệ',
                                  style: MayTypography.bodyMedium(context)),
                              SizedBox(width: MaySpacing.s4),
                              Text('*',
                                  style: TextStyle(
                                      color: MayColors.danger, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: MaySpacing.s8),
                          MaySegmentedControl<HouseholdCurrency>(
                            options: {
                              HouseholdCurrency.vnd: 'VND',
                              HouseholdCurrency.usd: 'USD'
                            },
                            selected: _currency,
                            onChanged: (v) => setState(() => _currency = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MaySpacing.s16),
                  // Timezone field
                  MayCard.flat(
                    child: Padding(
                      padding: const EdgeInsets.all(MaySpacing.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MayText('Múi giờ',
                              style: MayTypography.bodyMedium(context)),
                          SizedBox(height: MaySpacing.s8),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: MaySpacing.s16, vertical: 14.0),
                              decoration: BoxDecoration(
                                color: MayColors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                      child: Text(_timezone,
                                          style:
                                              const TextStyle(fontSize: 16))),
                                  Icon(Icons.edit_outlined,
                                      size: 20, color: MayColors.secondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MaySpacing.s32),
                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: EdgeInsets.all(MaySpacing.s12),
                      decoration: BoxDecoration(
                        color: MayColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 20, color: MayColors.danger),
                          SizedBox(width: MaySpacing.s8),
                          Expanded(
                              child: MayText(_error!,
                                  style: TextStyle(
                                      color: MayColors.danger, fontSize: 14))),
                        ],
                      ),
                    ),
                    SizedBox(height: MaySpacing.s16),
                  ],
                  // Submit button
                  MayButton.primary(
                    label: 'Tạo hộ gia đình',
                    onPressed: _submitting ? null : _createHousehold,
                    isLoading: _submitting,
                  ),
                  SizedBox(height: MaySpacing.s32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
