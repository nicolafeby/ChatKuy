import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

part 'call_history_store.g.dart';

class CallHistoryStore = _CallHistoryStore with _$CallHistoryStore;

abstract class _CallHistoryStore with Store {
  _CallHistoryStore({UserRepository? userRepository}) : _userRepository = userRepository;

  final UserRepository? _userRepository;
  final Set<String> _loadingPeerUids = <String>{};

  @observable
  bool isSearching = false;

  @observable
  String searchQuery = '';

  @observable
  ObservableList<CallHistoryEntry> entries = ObservableList<CallHistoryEntry>();

  @observable
  ObservableMap<String, String> peerNameByUid = ObservableMap<String, String>();

  @computed
  List<CallHistoryGroup> get groups {
    if (entries.isEmpty) return const [];

    final grouped = <CallHistoryGroup>[];
    CallHistoryGroup? currentGroup;

    for (final entry in entries) {
      if (currentGroup == null || !currentGroup.canMerge(entry)) {
        currentGroup = CallHistoryGroup(entries: [entry]);
        grouped.add(currentGroup);
        continue;
      }

      currentGroup.entries.add(entry);
    }

    return grouped;
  }

  @computed
  List<CallHistoryGroup> get filteredGroups {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return groups;

    return groups.where((group) {
      final resolvedName = peerNameByUid[group.peerUid];
      return group.matches(query, resolvedPeerName: resolvedName);
    }).toList();
  }

  @computed
  String get emptyMessage {
    return searchQuery.trim().isEmpty ? 'Belum ada riwayat telepon' : 'Riwayat panggilan tidak ditemukan';
  }

  @action
  void showSearch() {
    isSearching = true;
  }

  @action
  void hideSearch() {
    isSearching = false;
    searchQuery = '';
  }

  @action
  void setSearchQuery(String value) {
    searchQuery = value;
  }

  @action
  void clearSearch() {
    searchQuery = '';
  }

  @action
  void cachePeerName({
    required String uid,
    required String name,
  }) {
    final trimmedName = name.trim();
    if (uid.isEmpty || trimmedName.isEmpty) return;
    if (peerNameByUid[uid] == trimmedName) return;

    peerNameByUid[uid] = trimmedName;
  }

  @action
  void setCallDocs({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String currentUid,
  }) {
    final nextEntries = docs
        .map((doc) => CallHistoryEntry.fromData(
              id: doc.id,
              data: doc.data(),
              currentUid: currentUid,
            ))
        .where((entry) => entry.createdAt != null)
        .toList();

    entries
      ..clear()
      ..addAll(nextEntries);

    _preloadPeerNames(nextEntries);
  }

  Future<String?> resolveAuthenticatedUid() async {
    final user = FirebaseAuth.instance.currentUser ?? await FirebaseAuth.instance.idTokenChanges().first;
    if (user == null) return null;

    await user.getIdToken(true);
    return user.uid;
  }

  void _preloadPeerNames(List<CallHistoryEntry> nextEntries) {
    final userRepository = _userRepository;
    if (userRepository == null) return;

    final peerUids = nextEntries.map((entry) => entry.peerUid).where((uid) => uid.isNotEmpty).toSet();

    for (final uid in peerUids) {
      if (peerNameByUid.containsKey(uid) || _loadingPeerUids.contains(uid)) {
        continue;
      }

      _loadingPeerUids.add(uid);
      userRepository
          .getUser(uid)
          .then((user) {
            runInAction(() {
              cachePeerName(uid: uid, name: user.name);
            });
          })
          .catchError((_) {})
          .whenComplete(() {
            runInAction(() {
              _loadingPeerUids.remove(uid);
            });
          });
    }
  }
}

class CallHistoryGroup {
  CallHistoryGroup({required this.entries});

  final List<CallHistoryEntry> entries;

  CallHistoryEntry get latest => entries.first;
  String get peerUid => latest.peerUid;
  String get peerName => latest.peerName;

  String displayTitle(String? resolvedName) {
    final name = resolvedName ?? peerName;
    if (entries.length <= 1) return name;
    return '$name (${entries.length})';
  }

  String get searchText {
    final buffer = StringBuffer(peerName.toLowerCase());

    for (final entry in entries) {
      buffer
        ..write(' ')
        ..write(entry.searchText);
    }

    return buffer.toString();
  }

  bool matches(String query, {String? resolvedPeerName}) {
    final resolvedName = resolvedPeerName?.trim().toLowerCase() ?? '';
    final text = resolvedName.isEmpty ? searchText : '$resolvedName $searchText';
    final terms = query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);

    return terms.every(text.contains);
  }

  bool canMerge(CallHistoryEntry entry) {
    return entry.peerUid == latest.peerUid &&
        entry.isOutgoing == latest.isOutgoing &&
        entry.isVideoCall == latest.isVideoCall &&
        entry.status == latest.status &&
        _isSameDay(entry.createdAt, latest.createdAt);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class CallHistoryEntry {
  const CallHistoryEntry({
    required this.id,
    required this.roomId,
    required this.peerUid,
    required this.peerName,
    required this.isOutgoing,
    required this.isVideoCall,
    required this.status,
    required this.createdAt,
    required this.answeredAt,
    required this.endedAt,
  });

  final String id;
  final String roomId;
  final String peerUid;
  final String peerName;
  final bool isOutgoing;
  final bool isVideoCall;
  final String? status;
  final DateTime? createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  bool get isMissedIncoming => !isOutgoing && (status == CallStatus.declined || status == CallStatus.missed);

  String get listDateLabel {
    final date = createdAt;
    if (date == null) return '';

    final diff = _dayDifference(date);
    final time = _timeLabel(date);

    if (diff == 0) return time;
    if (diff == 1) return 'Kemarin, $time';
    return '${date.day}/${date.month}/${date.year}, $time';
  }

  String get dayHeaderLabel {
    final date = createdAt;
    if (date == null) return 'Tidak diketahui';

    final diff = _dayDifference(date);
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get timeLabel => _timeLabel(createdAt);

  String get directionLabel {
    if (isMissedIncoming) return 'Tak terjawab';
    return isOutgoing ? 'Keluar' : 'Masuk';
  }

  String get resultLabel {
    if (status == CallStatus.declined) return 'Ditolak';
    if (status == CallStatus.missed) return 'Tak terjawab';
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return 'Tidak dijawab';
    }

    final duration = durationText;
    if (duration == null) return 'Berakhir';
    return duration;
  }

  String? get durationText {
    if (answeredAt == null || endedAt == null) return null;
    final seconds = endedAt!.difference(answeredAt!).inSeconds;
    if (seconds <= 0) return null;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) return '$seconds detik';
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get searchText {
    return [
      peerName,
      _directionSearchLabel,
      _resultSearchLabel,
      isVideoCall ? 'video' : 'audio suara telepon',
      status ?? '',
      _searchableDate(createdAt),
    ].join(' ').toLowerCase();
  }

  String get _directionSearchLabel {
    if (isMissedIncoming) return 'tak terjawab';
    return isOutgoing ? 'keluar outgoing' : 'masuk incoming';
  }

  String get _resultSearchLabel {
    if (status == CallStatus.declined) return 'ditolak';
    if (status == CallStatus.missed) return 'tak terjawab';
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return 'tidak dijawab';
    }

    final duration = durationText;
    if (duration == null) return 'berakhir';
    return duration;
  }

  static CallHistoryEntry fromData({
    required String id,
    required Map<String, dynamic> data,
    required String currentUid,
  }) {
    final isOutgoing = data[CallField.callerId] == currentUid;
    final peerUid = isOutgoing ? data[CallField.calleeId]?.toString() : data[CallField.callerId]?.toString();
    final peerName = isOutgoing ? data[CallField.calleeName]?.toString() : data[CallField.callerName]?.toString();

    return CallHistoryEntry(
      id: id,
      roomId: data[CallField.roomId]?.toString() ?? '',
      peerUid: peerUid ?? '',
      peerName: peerName?.isNotEmpty == true ? peerName! : 'Kontak',
      isOutgoing: isOutgoing,
      isVideoCall: data[CallField.type] == 'video',
      status: data[CallField.status] as String?,
      createdAt: _dateFromTimestamp(data[CallField.createdAt]),
      answeredAt: _dateFromTimestamp(data[CallField.answeredAt]),
      endedAt: _dateFromTimestamp(data[CallField.endedAt]),
    );
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _searchableDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return 'hari ini today $time';
    if (diff == 1) return 'kemarin yesterday $time';
    return '${date.day}/${date.month}/${date.year} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $time';
  }

  static String _timeLabel(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static int _dayDifference(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return today.difference(target).inDays;
  }
}
