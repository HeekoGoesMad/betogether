import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/friend_provider.dart';
import '../../../shared/models/user_model.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _isSearching = false;

  // Tracks UIDs where we have a pending request (from Firestore OR just sent)
  final Set<String> _pendingUids = {};
  bool _loadingPending = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Load UIDs that the current user has already sent a pending request to.
  Future<void> _loadPendingRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingPending = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _pendingUids.addAll(snapshot.docs.map((d) => d.data()['toUid'] as String));
          _loadingPending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPending = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        return;
      }
      setState(() => _isSearching = true);
      final repo = ref.read(friendRepositoryProvider);
      final results = await repo.searchByUsername(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(friendActionProvider);

    ref.listen<FriendActionState>(friendActionProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Friend',
          style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: GoogleFonts.lexendDeca(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: GoogleFonts.lexendDeca(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isSearching || _loadingPending
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  )
                : _results.isEmpty && _searchCtrl.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 48,
                                color:
                                    AppColors.textHint.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'No users found',
                              style: GoogleFonts.lexendDeca(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'Search for friends by username',
                              style: GoogleFonts.lexendDeca(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              final friendUids = ref.watch(friendUidsProvider).valueOrNull ?? [];
                              final isFriend = friendUids.contains(user.uid);
                              final isRequested = _pendingUids.contains(user.uid);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    backgroundImage: user.photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.photoUrl)
                                        : null,
                                    child: user.photoUrl.isEmpty
                                        ? Text(
                                            user.displayName.isNotEmpty
                                                ? user.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: GoogleFonts.lexendDeca(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user.displayName,
                                    style: GoogleFonts.lexendDeca(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '@${user.username}',
                                    style: GoogleFonts.lexendDeca(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: 90,
                                    height: 36,
                                    child: isFriend
                                        ? Center(
                                            child: Text(
                                              'Friends',
                                              style: GoogleFonts.lexendDeca(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : isRequested
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.success.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Requested',
                                                    style: GoogleFonts.lexendDeca(
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : ElevatedButton(
                                                onPressed: actionState.isLoading
                                                    ? null
                                                    : () async {
                                                        await ref
                                                            .read(friendActionProvider.notifier)
                                                            .sendRequest(user.uid);
                                                        // Optimistically mark as requested
                                                        if (mounted) {
                                                          setState(() {
                                                            _pendingUids.add(user.uid);
                                                          });
                                                        }
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                ),
                                                child: Text(
                                                  'Add',
                                                  style: GoogleFonts.lexendDeca(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
