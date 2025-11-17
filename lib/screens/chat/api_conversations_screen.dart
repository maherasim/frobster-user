import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/chat_api_models.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/chat/api_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/cached_image_widget.dart';

class ApiConversationsScreen extends StatefulWidget {
  const ApiConversationsScreen({super.key});

  @override
  State<ApiConversationsScreen> createState() => _ApiConversationsScreenState();
}

class _ApiConversationsScreenState extends State<ApiConversationsScreen> {
  final ScrollController _controller = ScrollController();
  final List<ChatConversation> _conversations = [];
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _page < _lastPage) {
        _loadMore();
      }
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _lastPage = 1;
      _conversations.clear();
    }
    setState(() => _isLoading = true);
    try {
      final result = await chatListConversations(page: _page);
      _conversations.addAll(result.conversations);
      _lastPage = result.pagination?.lastPage ?? _lastPage;
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_page >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      _page += 1;
      final result = await chatListConversations(page: _page);
      _conversations.addAll(result.conversations);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.lblChat, style: boldTextStyle(color: white)),
        backgroundColor: context.primaryColor,
        iconTheme: IconThemeData(color: white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _isLoading
            ? LoaderWidget().center()
            : _conversations.isEmpty
                ? NoDataWidget(
                    title: language.noConversation,
                    imageWidget: EmptyStateWidget(),
                  ).center()
                : ListView.separated(
                    controller: _controller,
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    itemCount:
                        _conversations.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (_isLoadingMore && index == _conversations.length) {
                        return LoaderWidget().paddingAll(16);
                      }
                      final c = _conversations[index];
                      final other = c.otherUser;
                      final preview = (c.lastSnippet?.trim().isNotEmpty == true)
                          ? c.lastSnippet!
                          : (c.lastMessage?.preview ?? '');
                      final date = (c.lastAt?.trim().isNotEmpty == true)
                          ? c.lastAt!
                          : (c.lastMessage?.createdAt ?? '');
                      return ListTile(
                        leading: other?.avatarUrl.validate().isNotEmpty == true
                            ? CachedImageWidget(
                                url: other!.avatarUrl.validate(),
                                height: 40,
                                width: 40,
                                circle: true,
                              )
                            : Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (other?.name.validate().isNotEmpty == true)
                                      ? other!.name.validate()[0].toUpperCase()
                                      : (c.title.validate().isNotEmpty
                                          ? c.title.validate()[0].toUpperCase()
                                          : '?'),
                                  style: boldTextStyle(color: context.primaryColor, size: 16),
                                ),
                              ),
                        title: Text(
                          other?.name.validate().isNotEmpty == true
                              ? other!.name
                              : c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: primaryTextStyle(),
                        ),
                        subtitle: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondaryTextStyle(),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(date,
                                style: secondaryTextStyle(size: 10)),
                            6.height,
                            if (c.unreadCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.primaryColor,
                                  borderRadius: radius(12),
                                ),
                                child: Text('${c.unreadCount}',
                                    style:
                                        boldTextStyle(color: white, size: 10)),
                              ),
                          ],
                        ),
                        onTap: () async {
                          final otherId = other?.id ?? 0;
                          ApiChatScreen(
                            conversationId: c.id,
                            otherUserId: otherId,
                            otherUserName:
                                (other?.name.validate().isNotEmpty == true)
                                    ? other!.name
                                    : c.title,
                            otherUserAvatarUrl: other?.avatarUrl,
                          ).launch(context);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}


