import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulz_app/features/reported_events/data/view_tracker.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Wrap un widget affiche poster pour tracker les vues reelles.
///
/// Declenche [ViewTracker.onSeen] quand l'affiche est >= 50% visible pendant
/// au moins 1 seconde continue.
class ReportedEventViewTracker extends StatefulWidget {
  final String eventId;
  final Widget child;

  const ReportedEventViewTracker({
    super.key,
    required this.eventId,
    required this.child,
  });

  @override
  State<ReportedEventViewTracker> createState() =>
      _ReportedEventViewTrackerState();
}

class _ReportedEventViewTrackerState extends State<ReportedEventViewTracker> {
  static const _threshold = 0.5;
  static const _dwell = Duration(seconds: 1);

  Timer? _timer;
  bool _counted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onVisibility(VisibilityInfo info) {
    if (_counted) return;
    if (info.visibleFraction >= _threshold) {
      _timer ??= Timer(_dwell, () {
        if (!mounted || _counted) return;
        _counted = true;
        ViewTracker.instance.onSeen(widget.eventId);
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('rep-view-${widget.eventId}'),
      onVisibilityChanged: _onVisibility,
      child: widget.child,
    );
  }
}
