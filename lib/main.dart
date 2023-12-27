import 'dart:async';

import 'package:talker/talker.dart';

class LawEnforcersSquad {
  final String uid;
  DateTime lastUpdate;
  int updatesLeft;

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
  Timer? timer;

  Scheduler(this.run, this.updateInterval);

  void add(LawEnforcersSquad squad) {
    squads.add(squad);
    if (timer == null) {
      _startTimer();
    }
  }

  void remove(LawEnforcersSquad squad) {
    Talker().info('Removing squad ${squad.uid}');
    squads.removeWhere((element) => element.uid == squad.uid);
    Talker().info('Squads dligos: ${squads.length}', 'Squads: $squads');

    if (squads.isEmpty) {
      _cancelTimer();
    }
  }

  void _startTimer() {
    timer = Timer.periodic(updateInterval, (Timer timer) {
      _handleScheduledRuns();
    });
  }

  void _cancelTimer() {
    Talker().info('Cancelling timer');
    timer?.cancel();
    timer = null;
  }

  void _handleScheduledRuns() {
    final now = DateTime.now();
    final squadsCopy = List<LawEnforcersSquad>.from(squads);

    for (final squad in squadsCopy) {
      final nextRunTime = squad.lastUpdate.add(updateInterval);

      if (now.isAfter(nextRunTime) && squad.updatesLeft > 0) {
        if (isReadyForUpdate(squad)) {
          run(squad.uid);
          squad.lastUpdate = now;
          squad.updatesLeft--;
          Talker()
              .error('Squad ${squad.uid} updated, ${squad.updatesLeft} left');

          if (squad.updatesLeft == 0) {
            remove(squad);
          }
        }
      }
    }

    Talker().warning('Squads dligos: ${squads.length}, ${squadsCopy.length}');
    if (squads.isEmpty) {
      Talker().good('No more squads to update');
      _cancelTimer();
    }
  }

  bool isReadyForUpdate(LawEnforcersSquad squad) {
    final now = DateTime.now();
    final nextRunTime = squad.lastUpdate.add(updateInterval);

    return now.isAfter(nextRunTime);
  }
}

void main() async {
  final scheduler = Scheduler(
    (String uid) {
      Talker().warning('Squad $uid is ready for update');
    },
    const Duration(seconds: 10),
  );

  final squad1 = LawEnforcersSquad('squad1', 3);
  final squad2 = LawEnforcersSquad('squad2', 2);
  final squad3 = LawEnforcersSquad('squad3', 2);
  scheduler.add(squad1);
  scheduler.add(squad2);
  scheduler.add(squad3);

  Future.delayed(const Duration(seconds: 25), () {
    Talker().error('Removing squad1');
    scheduler.remove(squad1);
  });
}
