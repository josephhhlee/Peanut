import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/map_model.dart';
import 'package:peanut/Models/quest_model.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/Map/map_selection_page.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/Utils/text_utils.dart';
import 'dart:developer';

class AddQuestPage extends StatefulWidget {
  static const routeName = "/add-quest";
  const AddQuestPage({super.key});

  @override
  State<AddQuestPage> createState() => _AddQuestPageState();
}

class _AddQuestPageState extends State<AddQuestPage> {
  final _formKey = GlobalKey<FormState>();
  final _questLocation = TextEditingController();
  final _rewards = TextEditingController();
  final _description = TextEditingController();
  final _title = TextEditingController();
  final _rewardsFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _questLocationFocus = FocusNode();
  final _titleFocus = FocusNode();
  final _quest = Quest.empty();

  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _questLocation.dispose();
    _questLocationFocus.dispose();
    _rewards.dispose();
    _rewardsFocus.dispose();
    _description.dispose();
    _descriptionFocus.dispose();
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _setStartLocation(MapModel? location) => setState(() {
        _quest.mapModel = location;
        _questLocation.text = location?.addr ?? "";
      });

  Future<void> _onCreatedQuest() async {
    Future<int> calculateRemainingPeanuts() async {
      final value = await DataStore().currentUser!.getPeanutCurrency();
      final remainingPeanuts = value - (int.parse(_rewards.text) + Configs.questCreateCost);
      return remainingPeanuts;
    }

    void onError(String msg) {
      context.loaderOverlay.hide();
      CommonUtils.toast(context, msg, backgroundColor: PeanutTheme.errorColor);
      setState(() => _buttonPressed = false);
    }

    if (_buttonPressed) return;

    final form = _formKey.currentState;
    if (form?.validate() ?? false) {
      setState(() => _buttonPressed = true);

      context.loaderOverlay.show();
      await calculateRemainingPeanuts().then((remaining) async {
        if (remaining >= 0) {
          await FirestoreService.runTransaction(((transaction) async {
            form?.save();
            _quest.create(transaction);
            DataStore().currentUser!.updatePeanutCurrency(remaining, transaction);
          })).onError((error, _) {
            log(error.toString());
            onError("An error has occurred, please try again later.");
          }).then((_) {
            context.loaderOverlay.hide();
            CommonUtils.toast(context, "Quest created");

            Navigator.pop(context);
          });
        } else {
          onError("Insufficient Peanut(s) to create quest.");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _floatingBtn(),
        backgroundColor: PeanutTheme.backGroundColor,
        appBar: AppBar(
          title: const Text("Create Quest"),
          elevation: 0,
          backgroundColor: PeanutTheme.primaryColor,
        ),
        body: _body(),
      ),
    );
  }

  Widget _floatingBtn() => FloatingActionButton.extended(
        heroTag: "FAB",
        elevation: 0,
        onPressed: _onCreatedQuest,
        label: Row(
          children: [
            const Icon(Icons.add, color: PeanutTheme.almostBlack),
            const SizedBox(width: 5),
            const Text(
              "Create Quest",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            const Text("(-"),
            CommonUtils.peanutCurrency(value: ((int.tryParse(_rewards.text) ?? 0) + Configs.questCreateCost).toString()),
            const Text(")"),
          ],
        ),
      );

  Widget _body() => Form(
        key: _formKey,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _titleField(),
              const SizedBox(height: 20),
              _questLocationField(),
              const SizedBox(height: 20),
              _rewardsField(),
              const SizedBox(height: 20),
              Expanded(child: _descriptionField()),
              const SizedBox(height: 65),
            ],
          ),
        ),
      );

  Widget _titleField() => PeanutTextFormField(
        controller: _title,
        focus: _titleFocus,
        maxLength: Configs.questTitleCharLimit,
        nextFocus: _questLocationFocus,
        label: "Quest Title",
        enableTitleCase: true,
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
        onSave: (value) => _quest.title = value?.trim(),
      );

  Widget _questLocationField() => Hero(
        tag: "quest_location",
        child: Material(
          type: MaterialType.transparency,
          child: PeanutTextFormField(
            tooltipMsg: "This will determine your quest marker",
            controller: _questLocation,
            focus: _questLocationFocus,
            nextFocus: _rewardsFocus,
            label: "Quest Location",
            suffixIcon: const Icon(Icons.arrow_circle_right_rounded, color: PeanutTheme.almostBlack),
            validator: (value) => value == null || value.isEmpty ? "Required" : null,
            readOnly: true,
            onTap: () async => await Navigation.push(context, MapSelectionPage.routeName, args: [_quest.mapModel, _setStartLocation]),
          ),
        ),
      );

  Widget _rewardsField() => PeanutTextFormField(
        tooltipMsg: "Rewards for question completion",
        controller: _rewards,
        focus: _rewardsFocus,
        nextFocus: _descriptionFocus,
        label: "Rewards",
        numbersOnly: true,
        prefixIcon: Image.asset(
          "assets/currency.png",
          fit: BoxFit.scaleDown,
          scale: 35,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Required";
          if (int.tryParse(value) == null) return "Invalid value";
          if (int.parse(value) < 1) return "Minimum of 1 Peanut is required";
          return null;
        },
        onSave: (value) => _quest.rewards = int.parse(value!),
      );

  Widget _descriptionField() => PeanutTextFormField(
        controller: _description,
        focus: _descriptionFocus,
        hint: "Describe the instructions and\nobjectives of your quest..",
        isDescription: true,
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
        onSave: (value) => _quest.description = value,
      );
}

class PeanutTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? tooltipMsg;

  final int? maxLine;
  final int? minLine;
  final int? maxLength;

  final bool readOnly;
  final bool enableTitleCase;
  final bool numbersOnly;
  final bool isDescription;

  final FocusNode? focus;
  final FocusNode? nextFocus;

  final TextEditingController? controller;

  final Widget? suffixIcon;
  final Widget? prefixIcon;

  final String? Function(String? value)? validator;
  final void Function()? onTap;
  final void Function(String value)? onChange;
  final void Function(String? value)? onSave;

  const PeanutTextFormField({
    super.key,
    this.controller,
    this.maxLine = 1,
    this.minLine,
    this.maxLength,
    this.label,
    this.hint,
    this.tooltipMsg,
    this.readOnly = false,
    this.enableTitleCase = false,
    this.numbersOnly = false,
    this.isDescription = false,
    this.focus,
    this.nextFocus,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.onTap,
    this.onChange,
    this.onSave,
  });

  InputDecoration decoration() => InputDecoration(
        filled: true,
        fillColor: PeanutTheme.white,
        border: const OutlineInputBorder(),
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: "",
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PeanutTheme.errorColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PeanutTheme.errorColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PeanutTheme.almostBlack),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: PeanutTheme.primaryColor),
        ),
      );

  void onFieldSubmitted(BuildContext context) {
    focus?.unfocus();
    if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: textFormField(context)),
        if (tooltipMsg != null) const SizedBox(width: 5),
        if (tooltipMsg != null) tooltip(),
      ],
    );
  }

  Widget textFormField(BuildContext context) => TextFormField(
        expands: isDescription,
        textAlignVertical: TextAlignVertical.top,
        controller: controller,
        readOnly: readOnly,
        autofocus: false,
        focusNode: focus,
        maxLines: isDescription ? null : maxLine,
        minLines: minLine,
        maxLength: isDescription ? Configs.descriptionCharLimit : maxLength,
        style: const TextStyle(color: PeanutTheme.almostBlack),
        decoration: decoration(),
        keyboardType: isDescription
            ? TextInputType.multiline
            : numbersOnly
                ? TextInputType.number
                : null,
        textCapitalization: enableTitleCase
            ? TextCapitalization.words
            : isDescription
                ? TextCapitalization.sentences
                : TextCapitalization.none,
        inputFormatters: enableTitleCase
            ? [TitleCaseTextFormatter()]
            : numbersOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        onFieldSubmitted: (_) => onFieldSubmitted(context),
        onTap: onTap,
        onChanged: onChange == null ? null : (value) => onChange!(value.trim()),
        onSaved: onSave == null ? null : (value) => onSave!(value?.trim()),
        validator: validator == null ? null : (value) => validator!(value?.trim()),
      );

  Widget tooltip() => Tooltip(
        message: tooltipMsg,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(Icons.help, color: PeanutTheme.primaryColor.withOpacity(0.8), size: 23),
      );
}
