import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import 'conversation_screen.dart';
import '../auth/login_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuth = context.read<AuthProvider>().isAuth;
      if (isAuth) {
        context.read<MessageProvider>().loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuth;
    final messageProvider = context.watch<MessageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isAuth) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Messages & Chats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to chat with people who found or lost items.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Sign In to Chat'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversations = messageProvider.conversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<MessageProvider>().loadConversations(),
        color: AppTheme.primaryColor,
        child: messageProvider.isLoading && conversations.isEmpty
            ? const Center(child: LoadingWidget(message: 'Loading conversations...'))
            : conversations.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const EmptyStateWidget(
                        title: 'No Messages Yet',
                        message: 'When you contact someone about an item, conversations will appear here.',
                        icon: Icons.mark_chat_unread_outlined,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final conv = conversations[i];
                      final hasUnread = conv.unreadCount > 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                            child: Text(
                              conv.otherUserName.isNotEmpty
                                  ? conv.otherUserName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.otherUserName,
                                  style: TextStyle(
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 16,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ),
                              if (conv.lastMessageAt != null)
                                Text(
                                  AppHelpers.formatRelativeTime(conv.lastMessageAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasUnread ? AppTheme.primaryColor : Colors.grey.shade400,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.lastMessage ?? 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: hasUnread ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500,
                                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  otherUserId: conv.otherUserId,
                                  otherUserName: conv.otherUserName,
                                ),
                              ),
                            );
                            if (mounted) {
                              context.read<MessageProvider>().loadConversations();
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
