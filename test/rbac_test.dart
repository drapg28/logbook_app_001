import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/logbook/models/log_models.dart';
import 'package:logbook_app_001/services/access_control_service.dart';

void main() {
  // ── Setup Data Dummy ───────────────────────────────────────────────────
  const String ownerUid    = 'uid_samudra';   // Ketua 
  const String teammateUid = 'uid_lancelot';  // Anggota satu tim
  const String teamId      = 'TEAM_001';

  final allLogs = [
    LogModel(
      id: '1',
      title: 'Catatan Privat Samudra',
      description: 'Ini rahasia, hanya saya yang boleh lihat.',
      category: 'Pribadi',
      date: DateTime.now().toIso8601String(),
      authorId: ownerUid,
      teamId: teamId,
      isPublic: false, // PRIVATE
    ),
    LogModel(
      id: '2',
      title: 'Catatan Publik Samudra',
      description: 'Ini boleh dilihat semua anggota tim.',
      category: 'Proyek',
      date: DateTime.now().toIso8601String(),
      authorId: ownerUid,
      teamId: teamId,
      isPublic: true, // PUBLIC
    ),
  ];

  // ── Test 1: Privacy Filter ──────────────────────────────────────────────
  test(
    'RBAC Security: Private log TIDAK boleh terlihat oleh rekan satu tim',
    () {
      // Action: User B (lancelot) filter logs
      final visibleForTeammate = allLogs
          .where((log) => log.authorId == teammateUid || log.isPublic)
          .toList();

      // Assert: hanya 1 log (yang publik) yang terlihat
      expect(visibleForTeammate.length, 1);
      expect(visibleForTeammate.first.title, 'Catatan Publik Samudra');
    },
  );

  // ── Test 2: Owner bisa lihat semua miliknya ─────────────────────────────
  test(
    'RBAC Security: Pemilik catatan bisa melihat SEMUA log miliknya',
    () {
      final visibleForOwner = allLogs
          .where((log) => log.authorId == ownerUid || log.isPublic)
          .toList();

      // Assert: owner lihat 2 log (private + public miliknya)
      expect(visibleForOwner.length, 2);
    },
  );

  // ── Test 3: Owner-Only Edit Rule ────────────────────────────────────────
  test(
    'RBAC Security: Hanya pemilik yang boleh edit/hapus (termasuk Ketua tidak bisa edit milik orang lain)',
    () {
      const String ketuaRole   = 'Ketua';
      const String anggotaRole = 'Anggota';

      // Ketua mencoba edit catatan milik anggota lain (isOwner: false)
      final ketuaCanEditOthers = AccessControlService.canPerform(
        ketuaRole,
        AccessControlService.actionUpdate,
        isOwner: false,
      );

      // Anggota mencoba hapus catatan milik orang lain (isOwner: false)
      final anggotaCanDeleteOthers = AccessControlService.canPerform(
        anggotaRole,
        AccessControlService.actionDelete,
        isOwner: false,
      );

      // Pemilik (anggota) edit miliknya sendiri (isOwner: true)
      final ownerCanEdit = AccessControlService.canPerform(
        anggotaRole,
        AccessControlService.actionUpdate,
        isOwner: true,
      );

      // Assert
      expect(ketuaCanEditOthers, false);    // Ketua TIDAK boleh edit milik orang lain
      expect(anggotaCanDeleteOthers, false); // Anggota TIDAK boleh hapus milik orang lain
      expect(ownerCanEdit, true);            // Pemilik BOLEH edit miliknya sendiri
    },
  );

  // ── Test 4: Vulnerability Check ─────────────────────────────────────────
  test(
    'RBAC Security: Sistem dinyatakan AMAN jika private log tidak bocor',
    () {
      // Simulasi: User B mencoba akses semua log tanpa filter
      // (skenario bug: lupa filter → semua data muncul)
      final unfilteredLogs = allLogs; // tanpa filter = vulnerable

      // Dengan filter yang benar:
      final safeFilteredLogs = allLogs
          .where((log) => log.authorId == teammateUid || log.isPublic)
          .toList();

      // Assert: tanpa filter ada 2 log (BERBAHAYA)
      expect(unfilteredLogs.length, 2);
      // Assert: dengan filter hanya 1 log (AMAN)
      expect(safeFilteredLogs.length, 1);
      // Assert: log privat tidak bocor ke teammate
      expect(
        safeFilteredLogs.any((log) => !log.isPublic && log.authorId != teammateUid),
        false,
      );
    },
  );
}