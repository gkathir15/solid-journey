import 'package:flutter/material.dart';
import 'phase7_integrated_agent.dart';

/// Phase 7 Home Screen - Complete Integration Demo
class Phase7Home extends StatefulWidget {
  const Phase7Home({super.key});

  @override
  State<Phase7Home> createState() => _Phase7HomeState();
}

class _Phase7HomeState extends State<Phase7Home> {
  late Phase7IntegratedAgent _agent;
  final List<String> _logs = [];
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _agent = Phase7IntegratedAgent();

    // Listen to logs
    _agent.loggingStream.listen((log) {
      setState(() {
        _logs.add(log);
        if (_logs.length > 100) _logs.removeAt(0); // Keep last 100 logs
      });
    });

    // Listen to output
    _agent.outputStream.listen((output) {
      final status = output['status'] as String? ?? 'unknown';
      setState(() {
        _status = status;
      });
    });
  }

  @override
  void dispose() {
    _agent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 7: Integrated Agent'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Demo Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_status', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _planParis(),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Plan Paris Trip'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _planBangkok(),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Plan Bangkok Trip'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _planTokyo(),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Plan Tokyo Trip'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Logs display
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.contains('❌');
                final isSuccess = log.contains('✅');
                final color = isError
                    ? Colors.red.shade100
                    : isSuccess
                        ? Colors.green.shade100
                        : Colors.grey.shade100;

                return Container(
                  color: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    log,
                    style: const TextStyle(fontSize: 11, fontFamily: 'Courier'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _planParis() {
    _agent.planTrip(
      country: 'France',
      city: 'Paris',
      vibes: ['historic', 'local', 'cultural', 'street_art', 'cafe_culture'],
      durationDays: 3,
    );
  }

  void _planBangkok() {
    _agent.planTrip(
      country: 'Thailand',
      city: 'Bangkok',
      vibes: ['street_food', 'spiritual', 'local', 'nightlife', 'shopping'],
      durationDays: 3,
    );
  }

  void _planTokyo() {
    _agent.planTrip(
      country: 'Japan',
      city: 'Tokyo',
      vibes: ['tech', 'cultural', 'serene', 'nightlife', 'local'],
      durationDays: 4,
    );
  }
}
