import 'package:flutter_test/flutter_test.dart';
import 'package:toster/main.dart';

void main() {
  test('Scheduler runs tasks after specified time', () async {
    final List<String> executedTasks = [];

    final scheduler = Scheduler(
      (String uid) {
        executedTasks.add(uid);
      },
      const Duration(seconds: 5),
    );

    final squad1 = LawEnforcersSquad('squad1', 3);
    final squad2 = LawEnforcersSquad('squad2', 2);
    final squad3 = LawEnforcersSquad('squad3', 2);

    scheduler.add(squad1);
    scheduler.add(squad2);
    scheduler.add(squad3);

    await Future.delayed(const Duration(seconds: 10));

    expect(executedTasks, contains('squad1'));
    expect(executedTasks, contains('squad2'));
    expect(executedTasks, contains('squad3'));
  });

  test('Scheduler removes squads after updates are completed', () async {
    final scheduler = Scheduler(
      (String uid) {},
      const Duration(seconds: 5),
    );

    final squad1 = LawEnforcersSquad('squad1', 1);
    final squad2 = LawEnforcersSquad('squad2', 1);

    scheduler.add(squad1);
    scheduler.add(squad2);

    await Future.delayed(const Duration(seconds: 10));

    expect(scheduler.squads, isEmpty);
  });

  test('Scheduler cancels timer when no more squads to update', () async {
    final scheduler = Scheduler(
      (String uid) {},
      const Duration(seconds: 5),
    );

    final squad1 = LawEnforcersSquad('squad1', 1);

    scheduler.add(squad1);

    await Future.delayed(const Duration(seconds: 10));

    expect(scheduler.squads, isEmpty);
    expect(scheduler.timer, isNull);
  });
}
