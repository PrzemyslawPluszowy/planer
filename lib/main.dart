import 'dart:async';
import 'dart:collection';

import 'package:talker/talker.dart';

class LawEnforcersSquad {
  final String uid;
  DateTime lastUpdate;
  int updatesLeft;
  DateTime? nextRunTime;

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
  bool get isEmpty => _squads.isEmpty;
  Future<void>? _future;
  final SplayTreeSet<LawEnforcersSquad> _squads =
      SplayTreeSet<LawEnforcersSquad>((a, b) {
    return a.uid == b.uid ? 0 : a.nextRunTime!.compareTo(b.nextRunTime!);
  });

  Scheduler(this.run, this.updateInterval);

  Future<void> add(LawEnforcersSquad squad) async {
    final tmp = _squads.lookup(squad);
    if (tmp != null) {
      squad.nextRunTime = tmp.nextRunTime;
      _squads.remove(tmp);
    } else {
      final now = DateTime.now();
      squad.nextRunTime = now.add(updateInterval);
    }
    _squads.add(squad);
    _scheduledRun();
  }

  void remove(LawEnforcersSquad squad) {
    _squads.remove(squad);
  }

  Future<void> _scheduledRun() async {
    final firstSquad = _squads.firstOrNull;
    if (firstSquad != null && _future == null) {
      final now = DateTime.now();
      final nextRunTime = firstSquad.nextRunTime!;
      final timeToNextRun = nextRunTime.difference(now);
      _future = Future.delayed(timeToNextRun, _handleScheduledRun);
    }
  }

  void _handleScheduledRun() {
    _future = null;
    final firstSquad = _squads.firstOrNull;
    if (firstSquad != null) {
      if (firstSquad.nextRunTime!.isAfter(DateTime.now())) {
        print('wykonalo');
        _scheduledRun();
        return;
      }
      if (firstSquad.updatesLeft > 0) {
        run(firstSquad.uid);
        firstSquad.lastUpdate = DateTime.now();
        firstSquad.updatesLeft--;
        _squads.remove(firstSquad);

        if (firstSquad.updatesLeft > 0) {
          add(firstSquad);
        } else {
          _scheduledRun();
        }
      } else {
        _squads.remove(firstSquad);
        _scheduledRun();
      }
    }
  }
}

void main() async {
  final scheduler = Scheduler(
    (String uid) {
      Talker().warning('Squad $uid runned');
    },
    const Duration(seconds: 5),
  );

  final squad1 = LawEnforcersSquad('squad1', 3);
  final squad2 = LawEnforcersSquad('squad2', 2);
  final squad3 = LawEnforcersSquad('squad3', 2);

  await scheduler.add(squad1);
  await scheduler.add(squad2);
  await scheduler.add(squad3);

  Future.delayed(const Duration(seconds: 5), () async {
    final squad4 = LawEnforcersSquad('squad4', 5);
    await scheduler.add(squad4);
  });

  await Future.delayed(const Duration(seconds: 25), () {
    scheduler.remove(squad1);
  });
}
