import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Live checklist for password rules; each line turns green when its rule is met.
class PasswordRequirementsTracker extends StatefulWidget {
  final TextEditingController controller;

  const PasswordRequirementsTracker({super.key, required this.controller});

  @override
  State<PasswordRequirementsTracker> createState() =>
      _PasswordRequirementsTrackerState();
}

class _PasswordRequirementsTrackerState extends State<PasswordRequirementsTracker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant PasswordRequirementsTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  static final _letterRe = RegExp(r'[A-Za-z]');
  static final _digitRe = RegExp(r'[0-9]');

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasLength = text.length >= 8;
    final hasLetter = _letterRe.hasMatch(text);
    final hasDigit = _digitRe.hasMatch(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementLine(
          label: language.passwordMinLengthEight,
          satisfied: hasLength,
        ),
        _RequirementLine(
          label: language.passwordMustIncludeLetter,
          satisfied: hasLetter,
        ),
        _RequirementLine(
          label: language.passwordMustIncludeNumber,
          satisfied: hasDigit,
        ),
      ],
    );
  }
}

class _RequirementLine extends StatelessWidget {
  final String label;
  final bool satisfied;

  const _RequirementLine({
    required this.label,
    required this.satisfied,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = gradientGreen;
    final inactiveColor = textSecondaryColorGlobal.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: satisfied ? activeColor : inactiveColor,
          ),
          8.width,
          Expanded(
            child: Text(
              label,
              style: satisfied
                  ? secondaryTextStyle(size: 12, color: activeColor).copyWith(
                        fontWeight: FontWeight.w600,
                      )
                  : secondaryTextStyle(size: 12, color: inactiveColor),
            ),
          ),
        ],
      ),
    );
  }
}
