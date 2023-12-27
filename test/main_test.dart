import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
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

    await scheduler.add(squad1);
    await scheduler.add(squad2);
    await scheduler.add(squad3);

    await Future.delayed(const Duration(seconds: 10));

    expect(executedTasks, contains('squad1'));
    expect(executedTasks, contains('squad2'));
    expect(executedTasks, contains('squad3'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('Scheduler removes squads after updates are completed', () async {
    final scheduler = Scheduler(
      (String uid) {},
      const Duration(seconds: 5),
    );

    final squad1 = LawEnforcersSquad('squad1', 1);
    final squad2 = LawEnforcersSquad('squad2', 1);

    await scheduler.add(squad1);
    await scheduler.add(squad2);

    await Future.delayed(const Duration(seconds: 10));

    expect(true, scheduler.isEmpty);
  });

  test('Scheduler cancels  when no more squads to update', () async {
    final scheduler = Scheduler(
      (String uid) {},
      const Duration(seconds: 5),
    );

    final squad1 = LawEnforcersSquad('squad1', 1);

    await scheduler.add(squad1);

    await Future.delayed(const Duration(seconds: 10));

    expect(true, scheduler.isEmpty);
  });

  test('Two object', () async {
    final scheduler = Scheduler(
      (String uid) {
        print('$uid, ${DateTime.now()}');
      },
      const Duration(seconds: 10),
    );

    final squad1 = LawEnforcersSquad('squad1', 4);
    final squad2 = LawEnforcersSquad('squad2', 4);

    await scheduler.add(squad1);
    print('${DateTime.now()}');
    await Future.delayed(const Duration(seconds: 2));
    await scheduler.add(squad2);
    scheduler.remove(squad1);
    print('${DateTime.now()}');
    await Future.delayed(const Duration(seconds: 30));

    // expect(true, scheduler.isEmpty);
  });
}
