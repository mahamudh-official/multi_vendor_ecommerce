import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/fulfillment_status.dart';

class FulfillmentTimelineCard extends StatelessWidget {
  final FulfillmentStatus currentStatus;
  final ValueChanged<FulfillmentStatus>? onAdvanceStatus;
  final bool isUpdating;

  const FulfillmentTimelineCard({
    super.key,
    required this.currentStatus,
    this.onAdvanceStatus,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final steps = [
      FulfillmentStatus.pending,
      FulfillmentStatus.confirmed,
      FulfillmentStatus.processing,
      FulfillmentStatus.shipped,
      FulfillmentStatus.delivered,
    ];

    final currentIndex = steps.indexOf(currentStatus);
    final isCancelled = currentStatus == FulfillmentStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fulfillment Pipeline',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: currentStatus.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentStatus.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: currentStatus.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This order has been cancelled. No further fulfillment actions can be performed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Horizontal Stepper Bar
            Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isEven) {
                  final stepIdx = i ~/ 2;
                  final isDone = stepIdx <= currentIndex;
                  final isCurrent = stepIdx == currentIndex;

                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? currentStatus.color
                          : isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '${stepIdx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black54,
                              ),
                            ),
                    ),
                  );
                } else {
                  final prevIdx = i ~/ 2;
                  final isPassed = prevIdx < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isPassed
                          ? currentStatus.color
                          : isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  );
                }
              }),
            ),
            const SizedBox(height: 12),

            // Step Labels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.map((st) {
                final isCurrent = st == currentStatus;
                return SizedBox(
                  width: 58,
                  child: Text(
                    st.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isCurrent
                          ? st.color
                          : isDark
                          ? Colors.grey[400]
                          : AppColorsLight.neutral600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Next Action Button
            if (currentStatus.nextStatus != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: isUpdating
                      ? null
                      : () => onAdvanceStatus?.call(currentStatus.nextStatus!),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    isUpdating
                        ? 'Updating...'
                        : 'Advance to ${currentStatus.nextActionLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentStatus.nextStatus!.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Order is fully fulfilled and delivered!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
