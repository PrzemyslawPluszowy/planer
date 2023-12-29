import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:bson/bson.dart';
import 'package:talker/talker.dart';

class Task {
  final String uid;

  final int updatesLeft;
  final DateTime nextRunTime;

  Task({
    required this.uid,
    required this.updatesLeft,
    required this.nextRunTime,
  });

  Task copyWith({
    String? uid,
    int? updatesLeft,
    DateTime? nextRunTime,
  }) {
    return Task(
      uid: uid ?? this.uid,
      updatesLeft: updatesLeft ?? this.updatesLeft,
      nextRunTime: nextRunTime ?? this.nextRunTime,
    );
  }

  factory Task.fromBson(Map<String, dynamic> bson) {
    return Task(
      uid: bson['uid'] as String,
      updatesLeft: bson['updatesLeft'] as int,
      nextRunTime: bson['nextRunTime'] as DateTime,
    );
  }

  Map<String, dynamic> toBson() => {
        'uid': uid,
        'updatesLeft': updatesLeft,
        'nextRunTime': nextRunTime,
      };
}

class Scheduler {
  final Duration updateInterval;
  final Function(String uid) run;
  final String filePatch;
  bool get isEmpty => _tasks.isEmpty;
  Future<void>? _future;
  final SplayTreeSet<Task> _tasks = SplayTreeSet<Task>((a, b) {
    return a.uid == b.uid ? 0 : a.nextRunTime.compareTo(b.nextRunTime);
  });

  Scheduler(this.run, this.updateInterval, this.filePatch) {
    if (File(filePatch).existsSync()) {
      final readBackup = _readBackup(filePatch);
      _tasks.addAll(readBackup);
      _scheduledRun();
    }
  }

  void add(String id, int updateLeft) {
    Task? task = Task(uid: id, updatesLeft: 0, nextRunTime: DateTime.now());
    task = _tasks.lookup(task);
    if (task != null) {
      // task.nextRunTime = tmp.nextRunTime;
      _tasks.remove(task);
      task = task.copyWith(updatesLeft: updateLeft);
    } else {
      final now = DateTime.now();
      task = Task(
          uid: id,
          updatesLeft: updateLeft,
          nextRunTime: now.add(updateInterval));
    }
    _tasks.add(task);
    _createBackup();

    _scheduledRun();
  }

  void remove(String id) {
    Talker().warning('Scheduler remove $id');
    _tasks.removeWhere((element) => element.uid == id);
    _createBackup();
  }

  Future<void> _scheduledRun() async {
    final firstTask = _tasks.firstOrNull;
    Talker().warning('Scheduler _scheduledRun ${firstTask?.uid}');
    if (firstTask != null && _future == null) {
      final now = DateTime.now();
      final nextRunTime = firstTask.nextRunTime;
      final timeToNextRun = nextRunTime.difference(now);
      _future = Future.delayed(timeToNextRun, _handleScheduledRun);
    }
  }

  Future<void> _handleScheduledRun() async {
    Talker().good('Scheduler _handleScheduledRun');
    _future = null;
    final firstTask = _tasks.firstOrNull;
    if (firstTask != null) {
      if (firstTask.nextRunTime.isAfter(DateTime.now())) {
        print('wykonalo');
        _scheduledRun();
        return;
      }
      if (firstTask.updatesLeft > 0) {
        run(firstTask.uid);
        final tmp = firstTask.copyWith(
          updatesLeft: firstTask.updatesLeft - 1,
        );

        _tasks.remove(firstTask);

        if (tmp.updatesLeft > 0) {
          add(tmp.uid, tmp.updatesLeft);
        } else {
          _scheduledRun();
        }
      } else {
        _tasks.remove(firstTask);
        _scheduledRun();
      }
    }
    _createBackup();
  }

  void _createBackup() {
    Talker().warning('Scheduler _createBackup ${_tasks.length}');
    try {
      final file = File(filePatch);
      var docToSave = <String, dynamic>{
        'list': _tasks.map((e) => e.toBson()).toList()
      };
      var bsonBinary = BsonCodec.serialize(docToSave);
      file.writeAsBytesSync(bsonBinary.byteList);

      Talker().good('succ', docToSave);
    } catch (e) {
      Talker().error('err: $e');
    }
  }

  List<Task> _readBackup(String path) {
    final file = File(path);
    final bsonBinary = file.readAsBytesSync();
    final doc = BsonCodec.deserialize(BsonBinary.from(bsonBinary));
    final list = doc['list'] as List;

    final tasks = list.map((e) {
      print((e['lastUpdate'].runtimeType));
      return Task.fromBson(e);
    }).toList();
    return tasks;
  }
}

void main() async {
  final scheduler = Scheduler(
      // filePatch: '../backup/tasks.bson',
      (String uid) {
    Talker().warning('Squad $uid runned');
  }, const Duration(seconds: 5));

  // scheduler.add('squad1', 3);
  // scheduler.add('squad2', 2);
  // scheduler.add('squad3', 2);

  // Future.delayed(const Duration(seconds: 5), () async {
  //   scheduler.add('squad4', 5);
  // });

  // await Future.delayed(const Duration(seconds: 25), () {
  //   scheduler.remove('squad1');
  // });
}
