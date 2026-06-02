import 'package:chatkuy/core/widgets/appbar_widget.dart';
import 'package:chatkuy/data/repositories/friend_request_repository.dart';
import 'package:chatkuy/di/injection.dart';
import 'package:chatkuy/stores/friend/add_friend_store.dart';
import 'package:chatkuy/core/config/language/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  AddFriendStore store = AddFriendStore(
    repository: getIt<FriendRequestRepository>(),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppbarWidget(title: AppTranslationKey.addFriend.tr),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslationKey.findFriendByUsername.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _UsernameInput(store: store),
              const SizedBox(height: 12),
              Observer(
                builder: (_) {
                  if (store.errorMessage == null) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    store.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  );
                },
              ),
              const Spacer(),
              Observer(
                builder: (_) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: store.canSubmit
                          ? () async {
                              final success = await store.addFriend();
                              if (!context.mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(AppTranslationKey.friendAdded.tr),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      child: store.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(AppTranslationKey.addFriend.tr),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput({
    required this.store,
  });

  final AddFriendStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return TextField(
          onChanged: store.setUsername,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppTranslationKey.usernameExample.tr,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        );
      },
    );
  }
}
