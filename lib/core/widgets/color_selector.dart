import 'package:flutter/material.dart';

/// Equal-sized touch targets with a visible and announced selection.
class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.colors,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final List<Color> colors;
  final int? value;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 48).floor().clamp(
        1,
        colors.length,
      );
      final width = (constraints.maxWidth / columns).clamp(48.0, 60.0);
      return Wrap(
        runSpacing: 8,
        children: [
          for (var i = 0; i < colors.length; i++)
            SizedBox(
              width: width,
              height: 56,
              child: Semantics(
                label: '$label ${i + 1}',
                selected: value == colors[i].toARGB32(),
                button: true,
                child: Tooltip(
                  message: '$label ${i + 1}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => onChanged(colors[i].toARGB32()),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: value == colors[i].toARGB32()
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: value == colors[i].toARGB32() ? 2 : 1,
                          ),
                        ),
                        child: value == colors[i].toARGB32()
                            ? Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: colors[i].computeLuminance() > .4
                                    ? Colors.black87
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
