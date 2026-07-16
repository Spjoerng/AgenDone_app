import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/schedule_colors.dart';
import '../../domain/schedule_formatters.dart';

class ScheduleEntryCard extends StatelessWidget {
  const ScheduleEntryCard({
    super.key,
    required this.entry,
    required this.hasConflict,
    required this.onTap,
  });
  final ScheduleEntry entry;
  final bool hasConflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                '${formatMinutes(context, entry.startMinutes)}\n${formatMinutes(context, entry.endMinutes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        color: ScheduleColors.resolve(entry.colorValue),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (hasConflict)
                                    Tooltip(
                                      message: 'Conflicts with another entry',
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        semanticLabel:
                                            'Conflicts with another entry',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                              if (entry.location != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.place_outlined, size: 18),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        entry.location!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
