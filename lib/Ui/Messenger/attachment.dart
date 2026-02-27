import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/file_model.dart';
import 'package:peanut/Services/image_picker_service.dart';
import 'package:peanut/ViewModels/chat_page_viewmodel.dart';

enum _Options {
  media,
  document,
  camera,
  location,
}

extension _OptionsExtension on _Options {
  String get name => toString().split('.').last;
  IconData get icon {
    switch (this) {
      case _Options.media:
        return FontAwesomeIcons.image;
      case _Options.document:
        return FontAwesomeIcons.paperclip;
      case _Options.camera:
        return FontAwesomeIcons.camera;
      case _Options.location:
        return FontAwesomeIcons.locationDot;
    }
  }
}

class AttachmentView extends StatefulWidget {
  final ChatPageViewModel viewModel;

  const AttachmentView({super.key, required this.viewModel});

  @override
  State<AttachmentView> createState() => _AttachmentViewState();
}

class _AttachmentViewState extends State<AttachmentView> {
  _Options? _selectedOption;
  final List<LocalFile> _attachments = [];
  final Duration _duration = const Duration(milliseconds: 300);
  Offset _offset = const Offset(0, 1);

  @override
  void initState() {
    widget.viewModel.openAttachment.value = _slideUp;
    super.initState();
  }

  void _slideUp() {
    _clearSelection();
    _offset = const Offset(0, 0);
    if (mounted) setState(() {});
  }

  void _slideDown() {
    _clearSelection();
    _offset = const Offset(0, 1);
    if (mounted) setState(() {});
  }

  void _clearSelection() {
    _selectedOption = null;
    _attachments.clear();
  }

  Future<void> _onSelectMedia() async {
    context.loaderOverlay.show();
    _attachments.addAll(await ImagePickerService.openGallery());
    context.loaderOverlay.hide();
    if (mounted) setState(() {});
  }

  Future<bool> _onBack() async {
    if (_selectedOption != null) {
      _clearSelection();
      setState(() {});
      return false;
    }
    if (_offset == const Offset(0, 0)) {
      _slideDown();
      return false;
    }
    return true;
  }

  void _onSend() {
    if (_attachments.isEmpty) return;

    switch (_selectedOption!) {
      case _Options.media:
        widget.viewModel.sendMediaMessage(_attachments);
        break;
      case _Options.document:
        break;
      case _Options.camera:
        break;
      case _Options.location:
        break;
    }
    _slideDown();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: AnimatedSlide(
        duration: _duration,
        offset: _offset,
        child: Container(
          color: PeanutTheme.transparent,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _spacer(),
              _body(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spacer() => Expanded(
        child: GestureDetector(
          onPanDown: (_) => _slideDown(),
          child: Container(
            width: double.infinity,
            color: PeanutTheme.transparent,
          ),
        ),
      );

  Widget _body() => AnimatedContainer(
        padding: const EdgeInsets.all(9),
        height: _selectedOption != null ? MediaQuery.of(context).size.height * 0.4 : 100,
        decoration: BoxDecoration(
          color: PeanutTheme.almostBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: PeanutTheme.primaryColor),
        ),
        curve: Curves.fastOutSlowIn,
        duration: _duration,
        child: _selectedOption != null ? _selectedView() : _options(),
      );

  Widget _options() {
    return Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 30),
            _icon(option: _Options.media, onTap: _onSelectMedia),
            const SizedBox(width: 30),
            _icon(option: _Options.document, onTap: () async => false),
            const SizedBox(width: 30),
            _icon(option: _Options.camera, onTap: () async => false),
            const SizedBox(width: 30),
            _icon(option: _Options.location, onTap: () async => false),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  Widget _icon({required _Options option, required Future<void> Function() onTap}) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _selectedOption == option ? PeanutTheme.white : PeanutTheme.almostBlack,
              border: _selectedOption == option ? Border.all(color: PeanutTheme.almostBlack, width: 5) : null,
              borderRadius: BorderRadius.circular(100),
            ),
            child: IconButton(
              tooltip: option.name,
              onPressed: () async {
                setState(() => _selectedOption = option);
                await onTap();
              },
              icon: Icon(
                option.icon,
                color: _selectedOption == option ? PeanutTheme.primaryColor : PeanutTheme.secondaryColor,
                size: _selectedOption == option ? 30 : null,
              ),
            ),
          ),
          const SizedBox(height: 3),
          if (_selectedOption != option)
            Text(
              option.name,
              style: const TextStyle(color: PeanutTheme.white, fontSize: 12),
            ),
        ],
      );

  Widget _selectedView() => Container(
        width: MediaQuery.of(context).size.width,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          children: [
            Expanded(child: _attachmentView()),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(child: _chatBar()),
                _floatingBtn(),
                const SizedBox(width: 5),
              ],
            ),
          ],
        ),
      );

  Widget _floatingBtn() => FloatingActionButton(
        elevation: 0,
        mini: true,
        backgroundColor: PeanutTheme.primaryColor,
        onPressed: _onSend,
        child: const Icon(Icons.send_rounded, color: PeanutTheme.almostBlack),
      );

  Widget _chatBar() => Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          child: TextField(
            autofocus: false,
            minLines: 1,
            maxLines: 4,
            maxLength: Configs.descriptionCharLimit,
            keyboardType: TextInputType.multiline,
            controller: widget.viewModel.typeController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(20.0),
              counterText: "",
              border: InputBorder.none,
              isDense: true,
              hintText: "Caption",
            ),
          ),
        ),
      );

  Widget _attachmentView() {
    Widget result = const SizedBox.shrink();

    switch (_selectedOption!) {
      case _Options.media:
        result = _mediaView();
        break;
      case _Options.document:
        break;
      case _Options.camera:
        break;
      case _Options.location:
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: PeanutTheme.primaryColor,
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: result,
          ),
        ),
      ),
    );
  }

  Widget _mediaView() {
    final list = List<LocalFile>.from(_attachments);
    final size = (MediaQuery.of(context).size.width / 3) - 8;

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        GestureDetector(
          onTap: _onSelectMedia,
          child: Tooltip(
            message: "Add More",
            child: SizedBox(
              height: size,
              width: size,
              child: const Icon(
                Icons.add_box_rounded,
                color: PeanutTheme.almostBlack,
                size: 80,
              ),
            ),
          ),
        ),
        ...list.map(
          (e) => Container(
            height: size,
            width: size,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: e.toImage(size: size),
            ),
          ),
        ),
      ],
    );
  }
}
