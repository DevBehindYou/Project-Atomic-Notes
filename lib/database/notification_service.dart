import 'package:atomic_notes/database/notification_models.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the in-app notification feed and tracks per-user read/dismiss state.
/// Singleton [ChangeNotifier], same shape as the other services. All writes go
/// through SECURITY DEFINER RPCs (see supabase/migrations/008).
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _uid => _sb.auth.currentUser?.id;

  List<AppNotification> _items = const [];
  bool _loading = false;
  String? _error;
  String? _boundUser;

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> init() async {
    final uid = _uid;
    if (uid != _boundUser) {
      _items = const [];
      _error = null;
      _boundUser = uid;
    }
    if (uid == null) return;
    await refresh();
  }

  void clear() {
    _items = const [];
    _error = null;
    _boundUser = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _sb.rpc('notifications_feed');
      _items = (rows as List)
          .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Could not load notifications.';
      debugPrint('NotificationService.refresh failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    // Optimistic: flip locally, then persist.
    _items = _items
        .map((n) => n.id == id ? _copyRead(n) : n)
        .toList(growable: false);
    notifyListeners();
    try {
      await _sb.rpc('notification_mark_read', params: {'p_id': id});
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    _items = _items.map(_copyRead).toList(growable: false);
    notifyListeners();
    try {
      await _sb.rpc('notification_mark_all_read');
    } catch (e) {
      debugPrint('markAllRead failed: $e');
    }
  }

  Future<void> dismiss(String id) async {
    _items = _items.where((n) => n.id != id).toList(growable: false);
    notifyListeners();
    try {
      await _sb.rpc('notification_dismiss', params: {'p_id': id});
    } catch (e) {
      debugPrint('dismiss failed: $e');
    }
  }

  AppNotification _copyRead(AppNotification n) => AppNotification(
        id: n.id,
        type: n.type,
        subject: n.subject,
        description: n.description,
        priority: n.priority,
        status: n.status,
        action: n.action,
        actionUrl: n.actionUrl,
        icon: n.icon,
        createdAt: n.createdAt,
        expiresAt: n.expiresAt,
        isRead: true,
        dismissedAt: n.dismissedAt,
        dismissible: n.dismissible,
      );
}
