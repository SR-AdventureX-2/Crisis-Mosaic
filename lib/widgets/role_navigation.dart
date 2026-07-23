import 'package:flutter/material.dart';

import '../design_system.dart';

enum RoleTab { command, resident }

class BottomRoleNavigation extends StatelessWidget {
  const BottomRoleNavigation({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final RoleTab active;
  final ValueChanged<RoleTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _NavigationButton(
              key: const Key('command-tab'),
              label: '指挥视角',
              icon: Icons.control_camera_outlined,
              selected: active == RoleTab.command,
              onTap: () => onSelected(RoleTab.command),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NavigationButton(
              key: const Key('resident-tab'),
              label: '居民上报',
              icon: Icons.radio_button_checked,
              selected: active == RoleTab.resident,
              onTap: () => onSelected(RoleTab.resident),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? MosaicColors.white : MosaicColors.mutedText;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? MosaicColors.lead : MosaicColors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? null
                  : Border.all(
                      color: withOpacityValue(MosaicColors.lead, 0.08),
                    ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x292E2A26),
                        blurRadius: 20,
                        offset: Offset(0, 7),
                      ),
                    ]
                  : MosaicShadow.subtle,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
