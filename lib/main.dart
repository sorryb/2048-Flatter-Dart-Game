
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const Puzzle64App());

class Puzzle64App extends StatelessWidget {
  const Puzzle64App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '64 - Combina numerele',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepOrange,
    ),
    home: const Puzzle64Page(),
  );
}

class Puzzle64Page extends StatefulWidget {
  const Puzzle64Page({super.key});

  @override
  State<Puzzle64Page> createState() => _Puzzle64PageState();
}

class _Puzzle64PageState extends State<Puzzle64Page> {
  final Random _random = Random();
  final TextEditingController _details = TextEditingController();

  List<int> _tiles = List.filled(16, 0);
  int _score = 0;
  int _moves = 0;
  bool _won = false;
  bool _lost = false;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      _tiles = List.filled(16, 0);
      _tiles[5] = 2;
      _tiles[10] = 2;
      _score = 0;
      _moves = 0;
      _won = false;
      _lost = false;
      _details.text =
          'Joc nou!\n\n'
          'Gliseaza sau foloseste sagetile. '
          'Uneste numere identice pana ajungi la 64.';
    });
  }

  bool _hasMoves(List<int> tiles) {
    if (tiles.contains(0)) return true;

    for (var i = 0; i < 16; i++) {
      if (i % 4 < 3 && tiles[i] == tiles[i + 1]) return true;
      if (i < 12 && tiles[i] == tiles[i + 4]) return true;
    }

    return false;
  }

  void _move(String direction) {
    if (_won || _lost) return;

    final next = List<int>.from(_tiles);
    final combinations = <String>[];
    var earned = 0;

    for (var line = 0; line < 4; line++) {
      final indices = List<int>.generate(4, (j) {
        switch (direction) {
          case 'left':
            return line * 4 + j;
          case 'right':
            return line * 4 + (3 - j);
          case 'up':
            return j * 4 + line;
          default:
            return (3 - j) * 4 + line;
        }
      });

      final values = indices
          .map((i) => next[i])
          .where((n) => n != 0)
          .toList();

      final merged = <int>[];

      for (var j = 0; j < values.length; j++) {
        if (j + 1 < values.length &&
            values[j] == values[j + 1]) {
          final result = values[j] * 2;
          merged.add(result);
          combinations.add(
            '${values[j]} + ${values[j]} = $result',
          );
          earned += result;
          j++;
        } else {
          merged.add(values[j]);
        }
      }

      for (var j = 0; j < 4; j++) {
        next[indices[j]] =
            j < merged.length ? merged[j] : 0;
      }
    }

    const directions = {
      'left': 'STANGA',
      'right': 'DREAPTA',
      'up': 'SUS',
      'down': 'JOS',
    };

    final label = directions[direction]!;

    final unchanged = List.generate(16, (i) => i)
        .every((i) => next[i] == _tiles[i]);

    if (unchanged) {
      setState(() {
        _details.text =
            'Mutare spre $label.\n\n'
            'Nicio piesa nu se poate deplasa. '
            'Incearca alta directie.';
      });
      return;
    }

    final victory = next.any((n) => n >= 64);
    int? spawned;

    if (!victory) {
      final empty = List.generate(16, (i) => i)
          .where((i) => next[i] == 0)
          .toList();

      if (empty.isNotEmpty) {
        spawned = _random.nextInt(10) == 0 ? 4 : 2;
        next[empty[_random.nextInt(empty.length)]] =
            spawned;
      }
    }

    final defeat = !victory && !_hasMoves(next);

    setState(() {
      _tiles = next;
      _score += earned;
      _moves++;
      _won = victory;
      _lost = defeat;

      _details.text = [
        'Mutarea $_moves: $label',
        combinations.isEmpty
            ? 'Piesele s-au deplasat fara combinari.'
            : 'Combinari:\n${combinations.join('\n')}',
        'Puncte castigate: $earned\n'
            'Scor total: $_score',
        if (spawned != null)
          'A aparut o piesa noua: $spawned.',
        if (victory)
          'BRAVO! Ai obtinut 64! Ai castigat!',
        if (defeat)
          'Joc terminat! Nu mai exista mutari posibile.',
      ].join('\n\n');
    });
  }

  Color _tileColor(int n) => switch (n) {
    0 => const Color(0xFFCDC1B4),
    2 => const Color(0xFFEEE4DA),
    4 => const Color(0xFFEDE0C8),
    8 => const Color(0xFFF2B179),
    16 => const Color(0xFFF59563),
    32 => const Color(0xFFF67C5F),
    64 => const Color(0xFFF65E3B),
    _ => const Color(0xFF3C3A32),
  };

  Widget _arrow(IconData icon, String direction) =>
      IconButton.filledTonal(
        onPressed: _won || _lost
            ? null
            : () => _move(direction),
        icon: Icon(icon, size: 30),
        iconSize: 30,
        constraints: const BoxConstraints(
          minWidth: 56,
          minHeight: 48,
        ),
        tooltip: direction,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = min(
              constraints.maxWidth - 24,
              constraints.maxHeight * 0.46,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '64 - Combina numerele',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _stat('SCOR', _score),
                        const SizedBox(width: 8),
                        _stat('MUTARI', _moves),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) {
                          _drag = Offset.zero;
                        },
                        onPanUpdate: (details) {
                          _drag += details.delta;
                        },
                        onPanEnd: (_) {
                          if (_drag.distance < 24) return;

                          if (_drag.dx.abs() >
                              _drag.dy.abs()) {
                            _move(
                              _drag.dx > 0
                                  ? 'right'
                                  : 'left',
                            );
                          } else {
                            _move(
                              _drag.dy > 0
                                  ? 'down'
                                  : 'up',
                            );
                          }
                        },
                        child: Container(
                          width: boardSize,
                          height: boardSize,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBADA0),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: GridView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 7,
                              mainAxisSpacing: 7,
                            ),
                            itemCount: 16,
                            itemBuilder: (context, i) {
                              final n = _tiles[i];

                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _tileColor(n),
                                  borderRadius:
                                      BorderRadius.circular(7),
                                ),
                                child: n == 0
                                    ? null
                                    : Text(
                                        '$n',
                                        style: TextStyle(
                                          fontSize:
                                              boardSize / 12,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: n <= 4
                                              ? const Color(
                                                  0xFF776E65,
                                                )
                                              : Colors.white,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    if (_won || _lost)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8),
                        child: Text(
                          _won
                              ? 'Bravo! Ai castigat!'
                              : 'Nu mai exista mutari!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: _won
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _arrow(
                            Icons.keyboard_arrow_up,
                            'up',
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _arrow(
                                Icons.keyboard_arrow_left,
                                'left',
                              ),
                              _arrow(
                                Icons.keyboard_arrow_down,
                                'down',
                              ),
                              _arrow(
                                Icons.keyboard_arrow_right,
                                'right',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    FilledButton.icon(
                      onPressed: _newGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Joc nou'),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Explicatia ultimei mutari',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextField(
                      controller: _details,
                      readOnly: true,
                      minLines: 5,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String title, int value) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 7,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFEEE4DA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF776E65),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF776E65),
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }
}
