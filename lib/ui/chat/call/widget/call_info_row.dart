import 'package:chatkuy/stores/chat/call/call_history_store.dart';
import 'package:flutter/material.dart';

class CallInfoRow extends StatelessWidget {
  const CallInfoRow({super.key, required this.entry});

  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isMissed = entry.isMissedIncoming;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        entry.isOutgoing ? Icons.call_made : Icons.call_received,
        color: isMissed ? Colors.redAccent : Colors.green,
      ),
      title: Text(entry.directionLabel),
      subtitle: Text(entry.timeLabel),
      trailing: Text(
        entry.resultLabel,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
