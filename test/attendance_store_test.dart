import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance_tracker/main.dart';

void main() {
  group('Attendance calculations', () {
    test('calculates percentage', () {
      final s = Subject(id: '1', name: 'Test', code: 'T1', color: const Color(0xFF000000), present: 18, absent: 2);
      expect(s.percentage, 90);
    });

    test('calculates classes needed to reach 75 percent', () {
      final store = AttendanceStore();
      final s = Subject(id: 'x', name: 'Test', code: 'T1', color: const Color(0xFF000000), present: 6, absent: 4);
      expect(store.classesNeeded(s), 6);
    });

    test('calculates safe absences when above target', () {
      final store = AttendanceStore();
      final s = Subject(id: 'x', name: 'Test', code: 'T1', color: const Color(0xFF000000), present: 18, absent: 2);
      expect(store.safeAbsences(s), 4);
    });
  });
}
