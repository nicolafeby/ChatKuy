import 'package:chatkuy/core/constants/firestore.dart';
import 'package:chatkuy/core/utils/extension/date.dart';
import 'package:chatkuy/core/widgets/base_layout.dart';
import 'package:chatkuy/data/repositories/call_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> with BaseLayout {
  final CallRepository repository = getIt<CallRepository>();
  Future<String?>? _uidFuture;

  @override
  void initState() {
    super.initState();
    _uidFuture = _resolveAuthenticatedUid();
  }

  Future<String?> _resolveAuthenticatedUid() async {
    final user = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.idTokenChanges().first;
    if (user == null) return null;

    await user.getIdToken(true);
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Telepon',
          style: TextStyle(fontSize: 28.sp),
        ),
      ),
      body: FutureBuilder<String?>(
        future: _uidFuture,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUid = authSnapshot.data;
          if (currentUid == null) {
            return const Center(child: Text('Silakan masuk kembali'));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repository.watchCallHistory(uid: currentUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }

              final calls = snapshot.data?.docs ?? const [];
              if (calls.isEmpty) {
                return const Center(child: Text('Belum ada riwayat telepon'));
              }

              return ListView.separated(
                padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                itemCount: calls.length,
                separatorBuilder: (_, __) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final data = calls[index].data();
                  return _CallHistoryTile(
                    data: data,
                    currentUid: currentUid,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({
    required this.data,
    required this.currentUid,
  });

  final Map<String, dynamic> data;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = data[CallField.callerId] == currentUid;
    final callType = data[CallField.type] == 'video' ? 'video' : 'voice';
    final status = data[CallField.status] as String?;
    final createdAt = _dateFromTimestamp(data[CallField.createdAt]);
    final answeredAt = _dateFromTimestamp(data[CallField.answeredAt]);
    final endedAt = _dateFromTimestamp(data[CallField.endedAt]);
    final name = isOutgoing
        ? data[CallField.calleeName]?.toString()
        : data[CallField.callerName]?.toString();
    final isMissed = !isOutgoing &&
        (status == CallStatus.declined || status == CallStatus.missed);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 24.r,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(
          callType == 'video' ? Icons.videocam_outlined : Icons.call_outlined,
          color: colorScheme.primary,
        ),
      ),
      title: Text(
        name?.isNotEmpty == true ? name! : 'Kontak',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            size: 16.r,
            color: isMissed ? Colors.redAccent : colorScheme.onSurfaceVariant,
          ),
          4.horizontalSpace,
          Flexible(
            child: Text(
              _subtitle(
                status: status,
                callType: callType,
                answeredAt: answeredAt,
                endedAt: endedAt,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMissed ? Colors.redAccent : null,
              ),
            ),
          ),
        ],
      ),
      trailing: Text(
        createdAt?.daysAndTime ?? '',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11.sp, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  String _subtitle({
    required String? status,
    required String callType,
    required DateTime? answeredAt,
    required DateTime? endedAt,
  }) {
    final typeLabel = callType == 'video' ? 'Video' : 'Suara';
    if (status == CallStatus.declined) return 'Panggilan $typeLabel ditolak';
    if (status == CallStatus.missed) return 'Panggilan $typeLabel tak terjawab';
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return 'Panggilan $typeLabel berlangsung';
    }

    final duration = _durationText(answeredAt, endedAt);
    if (duration == null) return 'Panggilan $typeLabel berakhir';
    return 'Panggilan $typeLabel - $duration';
  }

  String? _durationText(DateTime? startedAt, DateTime? endedAt) {
    if (startedAt == null || endedAt == null) return null;
    final seconds = endedAt.difference(startedAt).inSeconds;
    if (seconds <= 0) return null;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) return '$remainingSeconds detik';
    return '$minutes menit ${remainingSeconds.toString().padLeft(2, '0')} detik';
  }

  DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
