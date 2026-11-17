import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

/// Displays the historical reliability color legend when the reader first opens
/// the book, or on demand from the reading menu.
class ReliabilityLegendBanner extends StatelessWidget {
  const ReliabilityLegendBanner({
    super.key,
    this.onDismiss,
  });

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مستندیت کے رنگوں کی رہنمائی',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'بند کریں',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'اس کتاب میں ہر تاریخی بات کو اس کی تحقیقی حیثیت کے مطابق مخصوص رنگ دیا گیا ہے۔ کسی بھی جملے پر ٹیپ کر کے اس کے حوالہ جات دیکھے جا سکیں گے۔',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...ReliabilityStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: status.colorForBrightness(brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.urduLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: status.colorForBrightness(brightness),
                            ),
                          ),
                          Text(
                            status.urduDescription,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
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
}
