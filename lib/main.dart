import 'dart:async';

class LawEnforcersSquad {
  final String uid;
  DateTime lastUpdate;
  int updatesLeft;
  int? nextRunTimeMilliseconds;

  LawEnforcersSquad(
    this.uid,
    this.updatesLeft,
  ) : lastUpdate = DateTime.now();

  LawEnforcersSquad copyWith({
    String? uid,
    DateTime? lastUpdate,
    int? updatesLeft,
  }) {
    return LawEnforcersSquad(
      uid ?? this.uid,
      updatesLeft ?? this.updatesLeft,
    );
  }
}

class Scheduler {
  final Duration updateInterval;
  final Function(String uid) run;
  final List<LawEnforcersSquad> squads = [];
  Completer<void>? _currentCompleter;

  Scheduler(this.run, this.updateInterval);

  Future<void> add(LawEnforcersSquad squad) async {
    final now = DateTime.now();
    squad.nextRunTimeMilliseconds =
        now.add(updateInterval).millisecondsSinceEpoch;

    squads.add(squad);
    _sortSquadsByNextRunTime();
    await _awaitScheduledRun();
  }

  void remove(LawEnforcersSquad squad) {
    squads.removeWhere((element) => element.uid == squad.uid);
    _sortSquadsByNextRunTime();
    _currentCompleter?.complete();
  }

  Future<void> _awaitScheduledRun() async {
    while (squads.isNotEmpty) {
      final squad = squads.first;
      final now = DateTime.now();
      final delay = squad.nextRunTimeMilliseconds! - now.millisecondsSinceEpoch;

      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }

      _currentCompleter = Completer<void>();

      if (delay > 0) {
        await Future.delayed(Duration(milliseconds: delay)).then((_) {
          _handleScheduledRun(squad);
        });
      } else {
        _handleScheduledRun(squad);
      }

      await _currentCompleter!.future;
    }
  }

  void _handleScheduledRun(LawEnforcersSquad squad) {
    run(squad.uid);
    squad.lastUpdate = DateTime.now();
    squad.updatesLeft--;

    if (squad.updatesLeft == 0) {
      remove(squad);
    } else {
      squad.nextRunTimeMilliseconds =
          squad.lastUpdate.add(updateInterval).millisecondsSinceEpoch;
      _sortSquadsByNextRunTime();
    }

    if (!_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }
  }

  void _sortSquadsByNextRunTime() {
    squads.sort((a, b) =>
        a.nextRunTimeMilliseconds!.compareTo(b.nextRunTimeMilliseconds!));
  }
}

void main() async {
  final scheduler = Scheduler(
    (String uid) {
      print('Squad $uid is ready for update');
    },
    const Duration(seconds: 10),
  );

  final squad1 = LawEnforcersSquad('squad1', 3);
  final squad2 = LawEnforcersSquad('squad2', 2);
  final squad3 = LawEnforcersSquad('squad3', 2);

  await scheduler.add(squad1);
  await scheduler.add(squad2);
  await scheduler.add(squad3);

  Future.delayed(const Duration(seconds: 5), () async {
    final squad4 = LawEnforcersSquad('squad4', 1);
    await scheduler.add(squad4);
  });

  await Future.delayed(const Duration(seconds: 25), () {
    scheduler.remove(squad1);
  });
}
