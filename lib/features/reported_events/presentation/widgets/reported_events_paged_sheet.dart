import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/reported_event_detail_sheet.dart';

/// Sheet swipable (PageView) entre les affiches de signalements.
/// Partage entre le carousel de bulles et le tap sur un pin de carte.
class ReportedEventsPagedSheet extends StatefulWidget {
  final List<ReportedEvent> events;
  final int initialIndex;

  const ReportedEventsPagedSheet({
    super.key,
    required this.events,
    required this.initialIndex,
  });

  @override
  State<ReportedEventsPagedSheet> createState() =>
      _ReportedEventsPagedSheetState();
}

class _ReportedEventsPagedSheetState extends State<ReportedEventsPagedSheet> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots indicateur
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.events.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  gradient: i == _current ? AppGradients.primary : null,
                  color: i == _current ? null : AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.events.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) => ReportedEventDetailSheet(
              event: widget.events[index],
            ),
          ),
        ),
      ],
    );
  }
}
