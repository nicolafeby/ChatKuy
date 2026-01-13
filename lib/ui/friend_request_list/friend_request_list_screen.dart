import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/friend_request/friend_request_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestScreen> with SingleTickerProviderStateMixin {
  FriendRequestStore store = FriendRequestStore(
    repository: getIt<FriendRequestRepository>(),
  );
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    store.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    store.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Permintaan Pertemanan',
          style: TextStyle(fontSize: 18.sp),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Masuk'),
            Tab(text: 'Terkirim'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingRequestTab(store: store),
          _OutgoingRequestTab(store: store),
        ],
      ),
    );
  }
}

class _IncomingRequestTab extends StatelessWidget {
  const _IncomingRequestTab({
    required this.store,
  });

  final FriendRequestStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final data = store.incomingRequests?.value;

        if (data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (data.isEmpty) {
          return const Center(
            child: Text('Tidak ada permintaan masuk'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final request = data[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.photoUrl != null ? NetworkImage(request.photoUrl!) : null,
                  child: request.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(request.displayName),
                subtitle: Text('@${request.username}'),
                trailing: Observer(
                  builder: (_) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            // TODO: reject request
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            await store.accept(
                              requestId: request.id,
                              fromUid: request.fromUid,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingRequestTab extends StatelessWidget {
  const _OutgoingRequestTab({
    required this.store,
  });

  final FriendRequestStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final data = store.outgoingRequests?.value;

        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.isEmpty) {
          return const Center(
            child: Text('Tidak ada permintaan terkirim'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final request = data[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.photoUrl != null ? NetworkImage(request.photoUrl!) : null,
                  child: request.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(request.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${request.username}'),
                    Row(
                      children: const [
                        Icon(
                          Icons.hourglass_top,
                          size: 14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Menunggu persetujuan',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
