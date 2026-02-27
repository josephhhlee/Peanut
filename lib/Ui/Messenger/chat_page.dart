import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:octo_image/octo_image.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/file_model.dart';
import 'package:peanut/Models/message_model.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/Messenger/attachment.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/Utils/scroll_utils.dart';
import 'package:peanut/ViewModels/chat_page_viewmodel.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChatPage extends StatefulWidget {
  static const routeName = "/chat";

  final String peerId;
  const ChatPage(this.peerId, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  final _refreshController = RefreshController();
  final _viewModel = ChatPageViewModel();
  final _showSendBtn = ValueNotifier(false);

  bool _loading = true;

  @override
  void initState() {
    _viewModel.init(widget.peerId, _refresh);
    _updateRead(true);
    super.initState();
  }

  @override
  void deactivate() {
    _updateRead(false);
    super.deactivate();
  }

  @override
  void dispose() {
    _showSendBtn.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _refresh({bool? load}) {
    if (load != null) _loading = load;
    if (mounted) setState(() {});
  }

  Future<void> _updateRead(bool read) async {
    final currentUserUid = DataStore().currentUser!.uid;
    await FirestoreService.usersInChatCol(formatChatId(currentUserUid, widget.peerId)).doc(currentUserUid).update({"read": read, "lastSeen": DateTime.now()});
  }

  void _onLoading() async {
    final success = await _viewModel.loadMoreMessages();
    success ? _refreshController.loadComplete() : _refreshController.loadNoData();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CommonUtils.loadingIndicator(expand: true);

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: PeanutTheme.backGroundColor,
        appBar: _appBar(),
        body: _body(),
      ),
    );
  }

  Widget _body() => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: _messagesList()),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(child: _chatBar()),
                    _floatingBtn(),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 80,
            child: ScrollToTopButton(controller: _scrollController, reverse: true),
          ),
          AttachmentView(viewModel: _viewModel),
        ],
      );

  AppBar? _appBar() => AppBar(
        title: Row(
          children: [
            CommonUtils.userImage(context: context, user: _viewModel.peer.value, size: 45),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewModel.peer.value.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.white, fontSize: 18),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _viewModel.peer,
                    builder: (_, value, __) => Text(
                      value.online ? "Online" : "Last seen recently",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: PeanutTheme.almostBlack, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [IconButton(onPressed: () => false, icon: const Icon(Icons.more_vert_outlined))],
        backgroundColor: PeanutTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: true,
      );

  Widget _floatingBtn() => ValueListenableBuilder(
        valueListenable: _showSendBtn,
        builder: (_, value, __) => AnimatedContainer(
          width: value ? 50 : 110,
          transformAlignment: Alignment.centerRight,
          clipBehavior: Clip.none,
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.only(right: 10),
          child: value
              ? FloatingActionButton(
                  heroTag: "FAB",
                  elevation: 0,
                  mini: true,
                  backgroundColor: PeanutTheme.primaryColor,
                  onPressed: () {
                    _viewModel.sendMessage();
                    _showSendBtn.value = false;
                    _refresh();
                  },
                  child: const Icon(Icons.send_rounded, color: PeanutTheme.almostBlack),
                )
              : Row(
                  children: [
                    Flexible(
                      child: ValueListenableBuilder(
                        valueListenable: _viewModel.openAttachment,
                        builder: (_, value, __) => FloatingActionButton(
                          heroTag: "MESSAGE",
                          elevation: 0,
                          mini: true,
                          backgroundColor: PeanutTheme.white,
                          onPressed: value,
                          child: const Icon(FontAwesomeIcons.paperclip, color: PeanutTheme.primaryColor),
                        ),
                      ),
                    ),
                    Flexible(
                      child: FloatingActionButton(
                        heroTag: "FAB",
                        elevation: 0,
                        mini: true,
                        backgroundColor: PeanutTheme.almostBlack,
                        onPressed: () {},
                        child: const Icon(Icons.keyboard_voice_outlined, color: PeanutTheme.white),
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _messagesList() => _viewModel.messages.isEmpty
      ? const Center(child: Text("You have no messages yet"))
      : DisableScrollGlow(
          child: SmartRefresher(
            scrollController: _scrollController,
            physics: const ClampingScrollPhysics(),
            reverse: true,
            enablePullDown: false,
            enablePullUp: true,
            controller: _refreshController,
            onLoading: _onLoading,
            primary: false,
            footer: CustomFooter(
              builder: (_, mode) {
                Widget body = const SizedBox.shrink();
                if (mode == LoadStatus.loading || mode == LoadStatus.canLoading) body = CommonUtils.loadingIndicator();
                if (mode == LoadStatus.noMore) body = const Text("No more messages");
                return SizedBox(height: 55, child: Center(child: body));
              },
            ),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              reverse: true,
              itemCount: _viewModel.messages.length,
              itemBuilder: (context, index) => _message(_viewModel.messages[index]),
            ),
          ),
        );

  Widget _chatBar() => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 4, right: 3),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          child: TextField(
            autofocus: false,
            minLines: 1,
            maxLines: 4,
            maxLength: Configs.descriptionCharLimit,
            keyboardType: TextInputType.multiline,
            controller: _viewModel.typeController,
            onChanged: (value) => _showSendBtn.value = value.isNotEmpty,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(20.0),
              prefixIcon: GestureDetector(
                onTap: () => false,
                child: const Icon(Icons.emoji_emotions_outlined, size: 25),
              ),
              counterText: "",
              border: InputBorder.none,
              isDense: true,
              hintText: "Message",
            ),
          ),
        ),
      );

  Widget _message(Message message) {
    Widget result;

    BoxDecoration decoration = BoxDecoration(
      color: message.from == _viewModel.author.uid ? PeanutTheme.primaryColor.withOpacity(0.6) : PeanutTheme.lightGrey,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(25),
        topRight: const Radius.circular(25),
        bottomRight: message.from != _viewModel.author.uid ? const Radius.circular(25) : Radius.zero,
        bottomLeft: message.from == _viewModel.author.uid ? const Radius.circular(25) : Radius.zero,
      ),
    );

    switch (message.type) {
      case MessageType.standard:
        result = _standardMessage(message, decoration);
        break;
      case MessageType.media:
        result = _mediaMessage(message, decoration);
        break;
      case MessageType.file:
        result = _fileMessage(message);
        break;
      case MessageType.location:
        result = _locationMessage(message);
        break;
      case MessageType.voice:
        result = _voiceMessage(message);
        break;
    }

    return Padding(
      key: Key(message.id),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          _displayTime(message),
          Row(
            mainAxisAlignment: message.from == _viewModel.author.uid ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.from == _viewModel.author.uid) SizedBox(width: MediaQuery.of(context).size.width * 0.1),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: result,
                ),
              ),
              _timerIcon(message.status),
              _failedIcon(message.status),
              if (message.from != _viewModel.author.uid) SizedBox(width: MediaQuery.of(context).size.width * 0.1),
            ],
          ),
          _seen(message),
        ],
      ),
    );
  }

  Widget _displayTime(Message message) => _viewModel.shouldDisplayTime(message)
      ? Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(top: 15, bottom: 5),
          child: Text(
            _viewModel.getDateAndTimeFormat(message.createdOnDateTime),
            textAlign: TextAlign.center,
            style: TextStyle(color: PeanutTheme.almostBlack.withOpacity(0.7), fontSize: 12.0, fontStyle: FontStyle.italic),
          ),
        )
      : const SizedBox.shrink();

  Widget _timerIcon(MessageStatus status) => status == MessageStatus.sending
      ? Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 3),
          child: CommonUtils.loadingIndicator(size: 14),
        )
      : const SizedBox.shrink();

  Widget _failedIcon(MessageStatus status) => status == MessageStatus.failed
      ? const Padding(
          padding: EdgeInsets.only(left: 1, bottom: 1),
          child: Icon(Icons.error, color: PeanutTheme.errorColor, size: 17),
        )
      : const SizedBox.shrink();

  Widget _seen(Message message) => ValueListenableBuilder(
        valueListenable: _viewModel.chat,
        builder: (_, value, __) {
          if (_viewModel.messages.indexOf(message) != 0 || message.from != _viewModel.author.uid || message.status != MessageStatus.sent) return const SizedBox.shrink();
          if (!value.read && value.lastSeen < message.createdOn) return const SizedBox.shrink();

          return Container(
            width: double.infinity,
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(right: 10, top: 5),
            child: const Text(
              "Seen",
              style: TextStyle(fontSize: 12),
            ),
          );
        },
      );

  Widget _standardMessage(Message message, BoxDecoration decoration) {
    final text = message.text ?? "";

    final matches = Configs.urlRegex.allMatches(text);
    List<Widget> previews = matches.map((urlMatch) {
      final link = text.substring(urlMatch.start, urlMatch.end);
      return Container(
        decoration: BoxDecoration(
          color: PeanutTheme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: LinkPreview(
          text: link,
          onPreviewDataFetched: (previewData) async {
            await DataStore.storeLinkPreview(link, previewData);
            setState(() {});
          },
          previewData: DataStore.getLinkPreview(link),
          width: MediaQuery.of(context).size.width * 0.8,
          hideImage: false,
          enableAnimation: true,
          imageBuilder: (url) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: url,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          padding: const EdgeInsets.all(10),
        ),
      );
    }).toList();

    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      decoration: decoration,
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: message.from == _viewModel.author.uid ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (previews.isNotEmpty) ...previews,
          SelectableLinkify(
            onOpen: (link) => false,
            text: message.text ?? "",
            style: const TextStyle(color: PeanutTheme.almostBlack, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _mediaMessage(Message message, BoxDecoration decoration) {
    Widget localImageView(Attachment attachment) {
      if (message.status != MessageStatus.sent || attachment.path == null) return const SizedBox.shrink();

      String? thumbnail = attachment.thumbnail;
      String? path = attachment.path;
      FileType type = attachment.type;

      Widget placeHolder() => Container(
            width: double.infinity,
            color: PeanutTheme.black,
            child: CommonUtils.loadingIndicator(size: 15),
          );

      Widget errorImage() => Image.asset(
            "assets/image_not_found.png",
            width: double.infinity,
            fit: BoxFit.fitHeight,
          );

      Image provider = Image.file(
        type == FileType.video && thumbnail != null ? File(thumbnail) : File(path!),
        width: double.infinity,
        fit: BoxFit.fitWidth,
      );

      return ClipRRect(
        key: Key(path!),
        borderRadius: BorderRadius.circular(20),
        child: OctoImage(
          image: provider.image,
          placeholderBuilder: (_) => placeHolder(),
          errorBuilder: (_, __, ___) => errorImage(),
          fit: BoxFit.fitWidth,
        ),
      );
    }

    Widget miniGallery() {
      List<Widget> children = [const SizedBox.shrink()];

      if (message.attachments!.length <= 2) children = message.attachments!.map((e) => localImageView(e)).toList();

      if (message.attachments!.length > 2) {
        final row1 = message.attachments!.sublist(0, 2);
        final row2 = message.attachments!.sublist(2, message.attachments!.length > 4 ? 4 : message.attachments!.length);

        children = [
          Row(children: row1.map((e) => Expanded(child: localImageView(e))).toList()),
          Row(children: row2.map((e) => Expanded(child: localImageView(e))).toList()),
        ];
      }

      return Container(
        decoration: BoxDecoration(
          color: PeanutTheme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(children: children),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      decoration: decoration,
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: message.from == _viewModel.author.uid ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          miniGallery(),
          if (message.text!.isNotEmpty)
            SelectableLinkify(
              onOpen: (link) => false,
              text: message.text ?? "",
              style: const TextStyle(color: PeanutTheme.almostBlack, fontSize: 18),
            ),
        ],
      ),
    );
  }

  Widget _fileMessage(Message message) => Container();
  Widget _locationMessage(Message message) => Container();
  Widget _voiceMessage(Message message) => Container();
}
