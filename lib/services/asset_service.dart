import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AssetService {
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Pengguna belum login.');
    }
    return uid;
  }

  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);

  CollectionReference get _assetsRef => _userDoc.collection('assets');

  CollectionReference get _schedulesRef => _userDoc.collection('schedules');

  int _parseCostToInt(dynamic rawCost) {
    if (rawCost == null) return 0;
    if (rawCost is num) return rawCost.round();
    final digits = rawCost.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  String _formatTanggalIndo(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month]} ${date.year}';
  }

  DateTime _extractHistoryDate(Map<String, dynamic> data) {
    final completedTs = data['completedAt'] as Timestamp?;
    if (completedTs != null) return completedTs.toDate();

    final createdTs = data['createdAt'] as Timestamp?;
    if (createdTs != null) return createdTs.toDate();

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Sinkronkan riwayat perawatan paling baru ke field Detail Barang
  Future<void> syncLatestMaintenanceToAsset(String assetId) async {
    if (assetId.isEmpty) return;

    final assetRef = _assetsRef.doc(assetId);
    final historySnap = await assetRef.collection('maintenance_history').get();

    if (historySnap.docs.isEmpty) {
      await assetRef.update({
        'lastMaintenance': '-',
        'lastMaintenanceCost': 'Rp 0',
        'maintenanceDetail': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final sortedDocs = [...historySnap.docs]..sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();
        return _extractHistoryDate(dataB).compareTo(_extractHistoryDate(dataA));
      });

    final latestData = sortedDocs.first.data();
    final DateTime latestDate = _extractHistoryDate(latestData);
    final String formattedDate = latestDate.millisecondsSinceEpoch > 0
        ? _formatTanggalIndo(latestDate)
        : (latestData['maintenanceDate'] ?? '-').toString();

    final int costInt = _parseCostToInt(latestData['cost']);
    final String formattedCost = _formatRupiah(costInt);

    final String detailText = (latestData['detail'] ??
            latestData['notes'] ??
            latestData['title'] ??
            '')
        .toString()
        .trim();

    await assetRef.update({
      'lastMaintenance': formattedDate,
      'lastMaintenanceCost': formattedCost,
      'maintenanceDetail': detailText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Kompresi & Konversi Foto ke Base64 Data URI (Gratis Tanpa Firebase Storage)

  Future<String> uploadAssetImage(File imageFile) async {
    final Uint8List rawBytes = await imageFile.readAsBytes();

    final ui.Codec codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: 720,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final Uint8List finalBytes =
        byteData != null ? byteData.buffer.asUint8List() : rawBytes;

    final Uint8List chosenBytes =
        finalBytes.lengthInBytes > 750000 ? rawBytes : finalBytes;

    if (chosenBytes.lengthInBytes > 850000) {
      throw Exception(
        'Ukuran foto terlalu besar. Gunakan foto dengan resolusi lebih kecil.',
      );
    }

    final String base64Str = base64Encode(chosenBytes);
    return 'data:image/jpeg;base64,$base64Str';
  }

  Future<void> deleteAssetImageByUrl(String photoUrl) async {
    // Tidak perlu menghapus dari Storage karena foto tersimpan di dokumen Firestore
  }

  // CRUD Data Barang (Assets)

  Stream<QuerySnapshot> getAssetsStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _assetsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addAsset(Map<String, dynamic> data) async {
    await _assetsRef.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAsset(String docId, Map<String, dynamic> data) async {
    await _assetsRef.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAsset(String docId) async {
    final assetRef = _assetsRef.doc(docId);

    final historySnapshot =
        await assetRef.collection('maintenance_history').get();
    final schedulesSnapshot =
        await _schedulesRef.where('assetId', isEqualTo: docId).get();

    final batch = _firestore.batch();
    for (final doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in schedulesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(assetRef);
    await batch.commit();
  }

  // CRUD Riwayat Perawatan (Maintenance History)

  Stream<List<QueryDocumentSnapshot>> getAllMaintenanceHistoryStream() {
    if (_auth.currentUser == null) return const Stream.empty();

    return _assetsRef.snapshots().asyncMap((assetsSnap) async {
      if (assetsSnap.docs.isEmpty) return <QueryDocumentSnapshot>[];

      final futures = assetsSnap.docs.map(
        (assetDoc) =>
            assetDoc.reference.collection('maintenance_history').get(),
      );

      final snapshots = await Future.wait(futures);
      return snapshots.expand((snap) => snap.docs).toList();
    });
  }

  Stream<QuerySnapshot> getAssetMaintenanceHistoryStream(String assetId) {
    if (_auth.currentUser == null) return const Stream.empty();
    return _assetsRef
        .doc(assetId)
        .collection('maintenance_history')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addMaintenanceRecord({
    required String assetId,
    required String assetName,
    required String maintenanceDate,
    required String cost,
    required String detail,
    String title = 'Perawatan Barang',
    String maintenanceType = 'Perawatan',
    DateTime? completedAtDate,
  }) async {
    final uid = _uid;
    final assetRef = _assetsRef.doc(assetId);
    final effectiveDate = completedAtDate ?? DateTime.now();

    await assetRef.collection('maintenance_history').add({
      'userId': uid,
      'assetId': assetId,
      'assetName': assetName,
      'title': title,
      'maintenanceType': maintenanceType,
      'maintenanceDate': maintenanceDate,
      'cost': cost,
      'detail': detail,
      'notes': detail,
      'completedAt': Timestamp.fromDate(effectiveDate),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await syncLatestMaintenanceToAsset(assetId);
  }

  Future<void> updateMaintenanceRecord({
    required String assetId,
    required String historyId,
    required String title,
    required String maintenanceType,
    required String maintenanceDate,
    required DateTime completedAtDate,
    required dynamic cost,
    required String detail,
  }) async {
    final assetRef = _assetsRef.doc(assetId);
    final historyRef = assetRef.collection('maintenance_history').doc(historyId);

    await historyRef.update({
      'title': title.trim(),
      'maintenanceType': maintenanceType,
      'maintenanceDate': maintenanceDate,
      'completedAt': Timestamp.fromDate(completedAtDate),
      'cost': cost,
      'detail': detail.trim(),
      'notes': detail.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Otomatis samakan Biaya & Tanggal Perawatan Terakhir di Detail Barang
    await syncLatestMaintenanceToAsset(assetId);
  }

  Future<void> deleteMaintenanceRecord({
    required String assetId,
    required String historyId,
  }) async {
    final assetRef = _assetsRef.doc(assetId);
    final historyRef = assetRef.collection('maintenance_history').doc(historyId);

    await historyRef.delete();
    await syncLatestMaintenanceToAsset(assetId);
  }

  // CRUD Jadwal Perawatan (Schedules)

  Stream<QuerySnapshot> getSchedulesStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    return _schedulesRef
        .orderBy('scheduledTimestamp', descending: false)
        .snapshots();
  }

  Future<void> addSchedule(Map<String, dynamic> scheduleData) async {
    await _schedulesRef.add({
      ...scheduleData,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    await _schedulesRef.doc(scheduleId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeSchedule({
    required String scheduleId,
    required String assetId,
    required String maintenanceTitle,
    required String dateFormatted,
    String assetName = '',
    String cost = 'Rp 0',
  }) async {
    final uid = _uid;
    final batch = _firestore.batch();

    batch.update(_schedulesRef.doc(scheduleId), {
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (assetId.isNotEmpty) {
      final assetRef = _assetsRef.doc(assetId);
      final historyRef = assetRef.collection('maintenance_history').doc();
      batch.set(historyRef, {
        'userId': uid,
        'assetId': assetId,
        'assetName': assetName,
        'title': maintenanceTitle,
        'maintenanceType': 'Perawatan',
        'maintenanceDate': dateFormatted,
        'cost': cost,
        'detail': maintenanceTitle,
        'notes': maintenanceTitle,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    if (assetId.isNotEmpty) {
      await syncLatestMaintenanceToAsset(assetId);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _schedulesRef.doc(scheduleId).delete();
  }
}