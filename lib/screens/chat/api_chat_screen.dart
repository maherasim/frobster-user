import 'dart:async';

import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/chat_api_models.dart';
import 'package:booking_system_flutter/model/chat_message_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/chat/widget/chat_item_widget.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/cached_image_widget.dart';
import '../../component/gradient_icon.dart';

class ApiChatScreen extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  const ApiChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
  });

  @override
  State<ApiChatScreen> createState() => _ApiChatScreenState();
}

class _ApiChatScreenState extends State<ApiChatScreen> {
  final TextEditingController messageCont = TextEditingController();
  final FocusNode messageFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<ApiChatMessage> _apiMessages = [];
  Timer? _pollTimer;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _reachedHistoryEnd = false;
  bool _isSending = false;
  bool _isFetchingNew = false;

  int get _lastMessageId => _apiMessages.isEmpty ? 0 : _apiMessages.last.id;
  int get _firstMessageId => _apiMessages.isEmpty ? 0 : _apiMessages.first.id;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
    _scrollController.addListener(_onScroll);
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) => _fetchNew());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 48 &&
        !_isLoadingMore &&
        !_reachedHistoryEnd &&
        !_isLoadingInitial) {
      _fetchOlder();
    }
  }

  Future<void> _fetchInitial() async {
    setState(() => _isLoadingInitial = true);
    try {
      final msgs = await chatFetchMessages(
        conversationId: widget.conversationId,
        afterId: 0,
        beforeId: 0,
        limit: 50,
      );
      _apiMessages
        ..clear()
        ..addAll(msgs);
      if (_apiMessages.isNotEmpty) {
        await chatMarkRead(
            conversationId: widget.conversationId, upToId: _lastMessageId);
      }
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _fetchNew() async {
    if (_isLoadingInitial || _isFetchingNew) return;
    _isFetchingNew = true;
    try {
      final msgs = await chatFetchMessages(
        conversationId: widget.conversationId,
        afterId: _lastMessageId,
        beforeId: 0,
        limit: 50,
      );
      if (msgs.isNotEmpty) {
        // Deduplicate based on ID to prevent race conditions showing "twice send"
        final existingIds = _apiMessages.map((e) => e.id).toSet();
        final newUnique = msgs.where((m) => !existingIds.contains(m.id)).toList();

        if (newUnique.isNotEmpty) {
          _apiMessages.addAll(newUnique);
          if (mounted) setState(() {});
          await chatMarkRead(
              conversationId: widget.conversationId, upToId: _lastMessageId);
        }
      }
    } catch (e) {
      // ignore ephemeral polling errors
    } finally {
      _isFetchingNew = false;
    }
  }

  Future<void> _fetchOlder() async {
    if (_apiMessages.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final msgs = await chatFetchMessages(
        conversationId: widget.conversationId,
        afterId: 0,
        beforeId: _firstMessageId,
        limit: 50,
      );
      if (msgs.isEmpty) {
        _reachedHistoryEnd = true;
      } else {
        _apiMessages.insertAll(0, msgs);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    // Prevent double-sending - check and set flag atomically
    if (_isSending) return;
    
    final text = messageCont.text.trim();
    if (text.isEmpty) {
      messageFocus.requestFocus();
      return;
    }

    // Set flag and update UI immediately to prevent double-tap
    setState(() {
      _isSending = true;
    });
    
    // Clear message immediately for instant feedback (like WhatsApp)
    messageCont.clear();
    
    try {
      // Send message in background - no blocking loader for better UX
      final res = await chatSendMessage(
        conversationId: widget.conversationId,
        message: text,
      );
      await _fetchNew();
      if (res.flagged) {
        final reason = res.piiTypes.join('/');
        toast('Message hidden due to policy (${reason})');
      }
    } catch (e) {
      toast(e.toString());
      // Restore message text if sending failed
      messageCont.text = text;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  List<ChatMessageModel> get _uiMessages {
    return _apiMessages.map((e) {
      final isMe = e.senderId == appStore.userId;
      int createdAtMs;
      try {
        createdAtMs = DateTime.parse(e.createdAt).millisecondsSinceEpoch;
      } catch (_) {
        createdAtMs = DateTime.now().millisecondsSinceEpoch;
      }
      final text = e.hidden ? 'Message hidden due to policy' : (e.message ?? '');
      final m = ChatMessageModel(
        senderId: isMe ? appStore.uid : widget.otherUserId.toString(),
        receiverId: isMe ? widget.otherUserId.toString() : appStore.uid,
        message: text,
        isMessageRead: e.read,
        createdAt: createdAtMs,
        messageType: MessageType.TEXT.name,
        attachmentfiles: const [],
      );
      m.isMe = isMe;
      return m;
    }).toList();
  }

  Widget _buildChatFieldWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appStore.isDarkMode
            ? context.cardColor
            : Colors.grey.shade200,
        borderRadius: radius(defaultRadius),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: appStore.isDarkMode ? context.cardColor : Colors.white,
              borderRadius: radius(defaultRadius),
              border: Border.all(
                color: gradientRed.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: AppTextField(
              textFieldType: TextFieldType.OTHER,
              controller: messageCont,
              textStyle: primaryTextStyle(),
              minLines: 1,
              onFieldSubmitted: (s) {
                if (!_isSending && messageCont.text.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
              focus: messageFocus,
              cursorHeight: 20,
              maxLines: 5,
              cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: language.message,
                hintStyle: secondaryTextStyle(),
                fillColor: Colors.transparent,
                filled: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ).expand(),
          8.width,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradientRed, gradientBlue],
              ),
              borderRadius: BorderRadius.circular(80),
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white),
              onPressed: _isSending
                  ? null
                  : () {
                      if (!_isSending && messageCont.text.trim().isNotEmpty) {
                        _sendMessage();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leadingWidth: context.width(),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light),
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: appPrimaryGradient),
          ),
          leading: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.symmetric(horizontal: 8),
                onPressed: () => finish(context),
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
              // Show first letter if no image, otherwise show image
              widget.otherUserAvatarUrl.validate().isNotEmpty
                  ? CachedImageWidget(
                      url: widget.otherUserAvatarUrl.validate(),
                      height: 36,
                      circle: true,
                      fit: BoxFit.cover)
                  : Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.otherUserName.validate().isNotEmpty
                            ? widget.otherUserName.validate()[0].toUpperCase()
                            : '?',
                        style: boldTextStyle(color: Colors.white, size: 16),
                      ),
                    ),
              12.width,
              Text(
                widget.otherUserName,
                style: boldTextStyle(color: white, size: APP_BAR_TEXT_SIZE),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).expand(),
              40.width,
            ],
          ),
        ),
        body: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryColor.withValues(alpha: 0.16),
                      brandAccentColor.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  if (_isLoadingInitial)
                    LoaderWidget().center().expand()
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding:
                            EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 80),
                        itemCount: _uiMessages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingMore && index == 0) {
                            return LoaderWidget().paddingBottom(8);
                          }
                          final msg =
                              _uiMessages[index - (_isLoadingMore ? 1 : 0)];
                          return ChatItemWidget(chatItemData: msg);
                        },
                      ),
                    ),
                ],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildChatFieldWidget(),
              ),
              // Removed blocking loader - messages appear instantly like WhatsApp
            ],
          ),
        ),
      ),
    );
  }
}


