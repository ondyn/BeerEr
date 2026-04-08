import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/widgets/keg_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a chart in landscape fullscreen mode with a back button.
///
/// Supports keg-level charts ('volume', 'rate') and participant-level
/// charts ('participant_volume', 'participant_bac') via the [chartChild]
/// parameter.
class FullscreenChartScreen extends StatefulWidget {
  const FullscreenChartScreen({
    super.key,
    required this.session,
    required this.pours,
    required this.chartType,
    this.prefs,
    this.chartChild,
  });

  final KegSession session;
  final List<Pour> pours;

  /// 'volume', 'rate', 'participant_volume', or 'participant_bac'.
  final String chartType;
  final FormatPreferences? prefs;

  /// Optional pre-built chart widget for participant-level charts.
  final Widget? chartChild;

  @override
  State<FullscreenChartScreen> createState() => _FullscreenChartScreenState();
}

class _FullscreenChartScreenState extends State<FullscreenChartScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title;
    switch (widget.chartType) {
      case 'volume':
        title = l10n.kegVolumeChart;
      case 'participant_volume':
        title = l10n.consumptionOverTime;
      case 'participant_bac':
        title = l10n.estimatedBacOverTime;
      default:
        title = l10n.pourRateChart;
    }

    Widget chart;
    if (widget.chartChild != null) {
      chart = widget.chartChild!;
    } else if (widget.chartType == 'volume') {
      chart = KegVolumeChart(
        session: widget.session,
        pours: widget.pours,
        prefs: widget.prefs ?? const FormatPreferences(),
      );
    } else {
      chart = PourRateChart(
        session: widget.session,
        pours: widget.pours,
      );
    }

    return Scaffold(
      backgroundColor: BeerColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 16, 16),
              child: chart,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: title,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
