import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Future<void>? _initFuture;

  void Function(String? payload)? _onNotificationTapCallback;
  String? _pendingLaunchPayload;

  static const String _channelId = 'keepora_maintenance_channel_vibrate5s';
  static const String _channelName = 'Pengingat Jadwal Perawatan';
  static const String _channelDesc =
      'Notifikasi pengingat jadwal perawatan dan perbaikan barang pribadi.';

  // Pola getar: 0ms jeda awal, lalu bergetar selama 5000ms (5 detik)
  static final Int64List _vibration5Seconds = Int64List.fromList([0, 5000]);

  /// Daftarkan handler navigasi saat notifikasi diketuk
  void setNotificationTapHandler(void Function(String? payload) onTap) {
    _onNotificationTapCallback = onTap;
    if (_pendingLaunchPayload != null) {
      final payload = _pendingLaunchPayload;
      _pendingLaunchPayload = null;
      onTap(payload);
    }
  }

  /// Ambil & hapus flag jika aplikasi dibuka dari ketukan notifikasi (cold start)
  String? consumePendingLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  Future<void> init() {
    if (_isInitialized) return Future.value();
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload ?? 'open_notifikasi';
          if (_onNotificationTapCallback != null) {
            _onNotificationTapCallback!(payload);
          } else {
            _pendingLaunchPayload = payload;
          }
        },
      );

      // Cek apakah aplikasi dibuka dari notifikasi saat aplikasi sedang tertutup
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload =
            launchDetails?.notificationResponse?.payload ?? 'open_notifikasi';
        if (_onNotificationTapCallback != null) {
          _onNotificationTapCallback!(payload);
        } else {
          _pendingLaunchPayload = payload;
        }
      }

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        final canExact =
            await androidImpl.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          await androidImpl.requestExactAlarmsPermission();
        }
      }

      _isInitialized = true;
    } catch (e) {
      _initFuture = null;
      debugPrint('Gagal inisialisasi notifikasi: $e');
    }
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final canExact =
          await androidImpl.canScheduleExactNotifications() ?? false;
      if (canExact) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Menghasilkan ID integer unik yang stabil dari scheduleId Firestore
  int _baseIdFromScheduleId(String scheduleId) {
    return (scheduleId.hashCode & 0x3FFFFFFF) * 2;
  }

  NotificationDetails _notificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      vibrationPattern: _vibration5Seconds,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Jadwalkan pengingat H-1 dan Hari-H untuk jadwal perawatan
  Future<void> scheduleMaintenanceReminder({
    required String scheduleId,
    required String title,
    required String assetName,
    required String maintenanceType,
    required DateTime scheduledAt,
  }) async {
    try {
      await init();
      await cancelMaintenanceReminder(scheduleId);

      final scheduleMode = await _resolveScheduleMode();
      final now = tz.TZDateTime.now(tz.local);
      final targetTime = tz.TZDateTime.from(scheduledAt, tz.local);
      final baseId = _baseIdFromScheduleId(scheduleId);

      // 1. Pengingat H-1 (24 jam sebelum jadwal)
      final reminderH1 = targetTime.subtract(const Duration(days: 1));
      if (reminderH1.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: baseId + 1,
          title: 'H-1: $title',
          body:
              '$maintenanceType untuk $assetName dijadwalkan besok pukul ${_formatJam(scheduledAt)} WIB.',
          scheduledDate: reminderH1,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: scheduleMode,
          payload: scheduleId,
        );
      }

      // 2. Pengingat Hari-H (tepat pada waktu jadwal)
      if (targetTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: baseId,
          title: 'Waktunya $maintenanceType!',
          body: 'Jadwal "$title" untuk barang $assetName dimulai sekarang.',
          scheduledDate: targetTime,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: scheduleMode,
          payload: scheduleId,
        );
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }

  /// Batalkan pengingat saat jadwal dihapus, diedit, atau ditandai selesai
  Future<void> cancelMaintenanceReminder(String scheduleId) async {
    try {
      await init();
      final baseId = _baseIdFromScheduleId(scheduleId);
      await _plugin.cancel(id: baseId);
      await _plugin.cancel(id: baseId + 1);
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi: $e');
    }
  }

  String _formatJam(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '$jam:$menit';
  }
}