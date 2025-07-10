import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class WashTab extends StatefulWidget {
  final BluetoothConnection connection;
  final Future<void> Function(int jetoane, String programName)? onProgramStarted;

  const WashTab({
    super.key,
    required this.connection,
    this.onProgramStarted,
  });

  @override
  State<WashTab> createState() => _WashTabState();
}

class _WashTabState extends State<WashTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int? _selectedProgramIndex;
  int _remainingSeconds = 0;
  int _totalTimeInSeconds = 0;
  Timer? _timer;
  bool _countdownStarted = false;
  bool _programStarted = false;
  bool _programFinished = false;

  final List<Map<String, dynamic>> programs = [
    {'name': 'Prespălare', 'jetoane': 1, 'timpPerJeton': 30, 'icon': Icons.water_drop},
    {'name': 'Spumă activă', 'jetoane': 1, 'timpPerJeton': 60, 'icon': Icons.bubble_chart},
    {'name': 'Clătire cu presiune', 'jetoane': 1, 'timpPerJeton': 90, 'icon': Icons.shower},
    {'name': 'Ceară lichidă', 'jetoane': 1, 'timpPerJeton': 60, 'icon': Icons.auto_awesome},
    {'name': 'Uscare finală', 'jetoane': 1, 'timpPerJeton': 30, 'icon': Icons.air},
  ];

  final List<Color> programColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.white,
  ];

  final Map<int, int> _jetoaneSelectate = {};

  void _startCountdown() {
    setState(() {
      _remainingSeconds = 5;
      _countdownStarted = true;
      _programStarted = false;
      _programFinished = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        _startProgram();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _startProgram() {
    final selected = programs[_selectedProgramIndex!];
    final jetoane = _jetoaneSelectate[_selectedProgramIndex!] ?? selected['jetoane'];
    _totalTimeInSeconds = selected['timpPerJeton'] * jetoane;

    setState(() {
      _remainingSeconds = _totalTimeInSeconds;
      _programStarted = true;
      _programFinished = false;
    });

    final command = 'start|$_selectedProgramIndex|$_totalTimeInSeconds\n';
    widget.connection.output.add(Uint8List.fromList(command.codeUnits));
    widget.connection.output.allSent;

    if (widget.onProgramStarted != null) {
      widget.onProgramStarted!(jetoane, selected['name']);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _programStarted = false;
          _countdownStarted = false;
          _programFinished = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Programe de spălare')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Alege un program de spălare:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final item = programs[index];
                  final selected = _selectedProgramIndex == index;
                  final jetoane = _jetoaneSelectate[index] ?? item['jetoane'];

                  return Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(item['icon'], size: 32, color: Colors.blueAccent),
                          title: Text(item['name']),
                          subtitle: Text('$jetoane jetoane • ${jetoane * item['timpPerJeton']} secunde'),
                          trailing: Radio<int>(
                            value: index,
                            groupValue: _selectedProgramIndex,
                            onChanged: (value) {
                              setState(() {
                                _selectedProgramIndex = value;
                                _programStarted = false;
                                _countdownStarted = false;
                                _programFinished = false;
                                _timer?.cancel();
                              });
                            },
                          ),
                        ),
                        if (selected)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _jetoaneSelectate[index] = (jetoane > 1) ? jetoane - 1 : 1;
                                    });
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('$jetoane jetoane'),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _jetoaneSelectate[index] = jetoane + 1;
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: programColors[index],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black26),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedProgramIndex != null && !_countdownStarted && !_programStarted && !_programFinished)
              ElevatedButton(
                onPressed: _startCountdown,
                child: const Text('Start Spălare'),
              ),
            const SizedBox(height: 16),
            if (_countdownStarted && !_programStarted)
              Text('Spălarea pornește în $_remainingSeconds secunde...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_programFinished)
              Column(
                children: [
                  Text(
                    'Program finalizat',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            if (_programStarted)
              Column(
                children: [
                  const Text(
                    'Spălare în desfășurare:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_remainingSeconds / _totalTimeInSeconds).clamp(0.0, 1.0),
                    minHeight: 10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}



