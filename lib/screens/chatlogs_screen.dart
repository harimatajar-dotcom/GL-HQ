import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/chatlogs_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';

class ChatlogsScreen extends StatefulWidget {
  const ChatlogsScreen({super.key});

  @override
  State<ChatlogsScreen> createState() => _ChatlogsScreenState();
}

class _ChatlogsScreenState extends State<ChatlogsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatlogsProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatlogsProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatlogsProvider>();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.findAncestorStateOfType<HomeScreenState>()?.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          provider.selectedSession != null ? 'Chat Session' : 'Chat Logs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (provider.selectedSession != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => provider.clearSelection(),
              tooltip: 'Close session',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.refresh(),
              tooltip: 'Refresh',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.selectedSession != null
          ? _ChatDetailView(session: provider.selectedSession!)
          : _SessionsListView(
              searchController: _searchController,
              scrollController: _scrollController,
            ),
    );
  }
}

class _SessionsListView extends StatelessWidget {
  final TextEditingController searchController;
  final ScrollController scrollController;

  const _SessionsListView({
    required this.searchController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatlogsProvider>();
    final sessions = provider.sessions;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search messages...',
              hintStyle: GoogleFonts.poppins(),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: provider.setSearchQuery,
          ),
        ),

        // Stats row
        if (!provider.isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum, size: 14, color: const Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Text(
                        '${sessions.length} sessions',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Sessions list
        Expanded(
          child: provider.loading && sessions.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: SkeletonCard(),
                  ),
                )
              : sessions.isEmpty && !provider.loading
                  ? const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No chat sessions',
                      subtitle: 'No chat logs available',
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.refresh(),
                      color: AppColors.accent,
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= sessions.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final session = sessions[index];
                          return _SessionCard(
                            session: session,
                            onTap: () => provider.selectSession(session),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final dynamic session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = session as dynamic;
    final lastActivity = s.lastActivity as DateTime?;
    final timeText = lastActivity != null ? _timeAgo(lastActivity) : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFF2DD4BF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      s.displayName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.shortId,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last active: $timeText',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble, size: 12, color: const Color(0xFF0F766E)),
                      const SizedBox(width: 4),
                      Text(
                        s.messageCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return DateFormat('MMM d').format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _ChatDetailView extends StatefulWidget {
  final dynamic session;

  const _ChatDetailView({required this.session});

  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant _ChatDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatlogsProvider>();
    final logs = provider.logs;

    if (provider.loading && logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logs.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages',
        subtitle: 'This session has no messages',
      );
    }

    // Group messages by date
    final grouped = _groupByDate(logs);

    return Column(
      children: [
        // Session header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF2DD4BF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.session.displayName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${logs.length} messages',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppColors.accent,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                return _DateGroup(
                  date: entry.key,
                  logs: entry.value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<dynamic>> _groupByDate(List<dynamic> logs) {
    final Map<String, List<dynamic>> grouped = {};
    for (final log in logs) {
      final date = DateFormat('yyyy-MM-dd').format(log.createdAt as DateTime);
      grouped.putIfAbsent(date, () => []).add(log);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<dynamic> logs;

  const _DateGroup({required this.date, required this.logs});

  @override
  Widget build(BuildContext context) {
    final displayDate = _formatDate(date);

    return Column(
      children: [
        // Date divider
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              displayDate,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ),

        // Messages
        ...logs.map((log) => _ChatBubble(log: log)),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}

class _ChatBubble extends StatelessWidget {
  final dynamic log;

  const _ChatBubble({required this.log});

  @override
  Widget build(BuildContext context) {
    final isUser = log.isUser as bool;
    final isSystem = log.isSystem as bool;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.message as String,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.muted : AppColors.accent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 4 : 14),
                bottomRight: Radius.circular(isUser ? 14 : 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUser)
                  Text(
                    log.displayName as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                if (isUser) const SizedBox(height: 4),
                SelectableText(
                  log.message as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isUser ? AppColors.foreground : Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(log.createdAt as DateTime),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
