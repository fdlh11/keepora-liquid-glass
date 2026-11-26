import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class JadwalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> _bulanSingkat = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna belum login.');
    }
    return user.uid;
  }

  CollectionReference get _schedulesRef =>
      _firestore.collection('users').doc(_uid).collection('schedules');

  CollectionReference get _assetsRef =>
      _firestore.collection('users').doc(_uid).collection('assets');

  String _formatRupiah(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  String _formatTanggalIndo(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month]} ${date.year}';
  }

  // Stream daftar jadwal aktif
  Stream<QuerySnapshot> streamJadwalAktif() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _schedulesRef.where('status', isEqualTo: 'pending').snapshots();
  }

  // Stream daftar barang milik pengguna untuk dropdown
  Stream<QuerySnapshot> streamDaftarBarang() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _assetsRef.orderBy('name', descending: false).snapshots();
  }

  // Tambah jadwal baru + pasang pengingat notifikasi lokal
  Future<void> tambahJadwal({
    required String title,
    required String assetId,
    required String assetName,
    required DateTime scheduledAt,
    required String maintenanceType,
    double estimatedCost = 0,
    String notes = '',
  }) async {
    final cleanTitle = title.trim();
    final docRef = await _schedulesRef.add({
      'title': cleanTitle,
      'assetId': assetId,
      'assetName': assetName,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'maintenanceType': maintenanceType,
      'estimatedCost': estimatedCost,
      'notes': notes.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.scheduleMaintenanceReminder(
      scheduleId: docRef.id,
      title: cleanTitle,
      assetName: assetName,
      maintenanceType: maintenanceType,
      scheduledAt: scheduledAt,
    );
  }

  // Perbarui detail jadwal + perbarui pengingat notifikasi lokal
  Future<void> updateJadwal({
    required String scheduleId,
    required String title,
    required String assetId,
    required String assetName,
    required DateTime scheduledAt,
    required String maintenanceType,
    double estimatedCost = 0,
    String notes = '',
  }) async {
    final cleanTitle = title.trim();
    await _schedulesRef.doc(scheduleId).update({
      'title': cleanTitle,
      'assetId': assetId,
      'assetName': assetName,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'maintenanceType': maintenanceType,
      'estimatedCost': estimatedCost,
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.scheduleMaintenanceReminder(
      scheduleId: scheduleId,
      title: cleanTitle,
      assetName: assetName,
      maintenanceType: maintenanceType,
      scheduledAt: scheduledAt,
    );
  }

  // Hapus jadwal + batalkan pengingat notifikasi lokal
  Future<void> hapusJadwal(String scheduleId) async {
    await _schedulesRef.doc(scheduleId).delete();
    await NotificationService.instance.cancelMaintenanceReminder(scheduleId);
  }

  // Tandai jadwal selesai, batalkan notifikasi, dan pindahkan ke riwayat perawatan aset
  Future<void> tandaiSelesai({
    required String scheduleId,
    required Map<String, dynamic> scheduleData,
  }) async {
    final batch = _firestore.batch();
    final scheduleDoc = _schedulesRef.doc(scheduleId);

    final num rawEstimate = (scheduleData['estimatedCost'] as num?) ?? 0;
    final double finalCost = rawEstimate.toDouble();

    batch.update(scheduleDoc, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String assetId = (scheduleData['assetId'] ?? '').toString();
    final String notes = (scheduleData['notes'] ?? '').toString().trim();
    final String title = (scheduleData['title'] ?? '').toString();
    final String detailText = notes.isNotEmpty ? notes : title;

    if (assetId.isNotEmpty) {
      final assetRef = _assetsRef.doc(assetId);
      final maintenanceDoc = assetRef.collection('maintenance_history').doc();

      batch.set(maintenanceDoc, {
        'userId': _uid,
        'scheduleId': scheduleId,
        'title': title,
        'assetId': assetId,
        'assetName': scheduleData['assetName'] ?? '',
        'maintenanceType': scheduleData['maintenanceType'] ?? 'Perawatan',
        'cost': finalCost,
        'detail': detailText,
        'notes': notes,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sinkronkan juga informasi perawatan terakhir pada dokumen aset
      batch.update(assetRef, {
        'lastMaintenance': _formatTanggalIndo(DateTime.now()),
        'lastMaintenanceCost': _formatRupiah(finalCost),
        if (detailText.isNotEmpty) 'maintenanceDetail': detailText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await NotificationService.instance.cancelMaintenanceReminder(scheduleId);
  }
}