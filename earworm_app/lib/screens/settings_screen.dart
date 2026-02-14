import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import '../providers/midi_input_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<MidiDevice> _devices = [];
  MidiDevice? _connected;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => _scanning = true);
    final devices = await ref.read(midiInputProvider).getDevices();
    setState(() {
      _devices = devices;
      _scanning = false;
    });
  }

  Future<void> _connect(MidiDevice device) async {
    await ref.read(midiInputProvider).connect(device);
    setState(() => _connected = device);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('MIDI Settings'),
        backgroundColor: const Color(0xFF16213E),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('MIDI Devices',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_scanning) const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) else IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _scanDevices,
                ),
              ],
            ),
          ),
          if (_devices.isEmpty && !_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No MIDI devices found.\nConnect your keyboard via USB and tap refresh.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, i) {
                final device = _devices[i];
                final isConnected = _connected?.name == device.name;
                return ListTile(
                  leading: Icon(
                    Icons.piano,
                    color: isConnected ? const Color(0xFF44CC66) : Colors.white54,
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    isConnected ? 'Connected' : 'Tap to connect',
                    style: TextStyle(
                      color: isConnected ? const Color(0xFF44CC66) : Colors.white38,
                    ),
                  ),
                  trailing: isConnected
                      ? const Icon(Icons.check_circle, color: Color(0xFF44CC66))
                      : null,
                  onTap: isConnected ? null : () => _connect(device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
