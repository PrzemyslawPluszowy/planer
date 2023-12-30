import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:toster/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Scheduler runs tasks after specified time', () async {
    final List<String> executedTasks = [];

    final scheduler = Scheduler((String uid) {
      executedTasks.add(uid);
      Talker().error('Scheduler executed', executedTasks);
    }, const Duration(seconds: 5),
        '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson');

    scheduler.add('squad1', 1);
    scheduler.add('squad2', 1);
    // await scheduler.add('squad3', 1);

    await Future.delayed(const Duration(seconds: 10));

    expect(true, executedTasks.contains('squad1'));
    expect(true, executedTasks.contains('squad2'));
    // expect(executedTasks, contains('squad3'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('Scheduler removes squads after updates are completed', () async {
    final scheduler = Scheduler((String uid) {}, const Duration(seconds: 5),
        '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson');

    scheduler.add('squad1', 1);
    scheduler.add('squad2', 1);

    await Future.delayed(const Duration(seconds: 10));

    expect(true, scheduler.isEmpty);
  });

  test('Scheduler cancels  when no more squads to update', () async {
    final scheduler = Scheduler(
      (String uid) {},
      const Duration(
        seconds: 5,
      ),
      '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson',
    );

    scheduler.add('squad1', 1);

    await Future.delayed(const Duration(seconds: 10));

    expect(true, scheduler.isEmpty);
  });

  test('Create backup', () async {
    final scheduler = Scheduler((String uid) {}, const Duration(seconds: 5),
        '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson');

    scheduler.add('test_task_1', 1);
    scheduler.add('test_task_2', 1);

    await Future.delayed(const Duration(seconds: 2));
    const fullPath =
        '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson';
    final file = File(fullPath);

    bool exists = await file.exists();

    expect(exists, true);

    final newSheduler = Scheduler((String uid) {}, const Duration(seconds: 2),
        '/Users/misiek440/kursy/bloc/new_clean/toster/toster/backup/tasks.bson');

    await Future.delayed(const Duration(seconds: 2));

    expect(true, newSheduler.isEmpty);
  });
}
