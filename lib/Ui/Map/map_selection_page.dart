import 'dart:async';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/properties.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/map_model.dart';
import 'package:peanut/Ui/Map/add_quest_page.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'dart:developer';

class MapSelectionPage extends StatefulWidget {
  static const routeName = "/map-selection";

  final List args;

  const MapSelectionPage(this.args, {super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _googlePlace = places.FlutterGooglePlacesSdk(Configs.googleAndroidApi);
  final _fieldController = TextEditingController();
  final _fieldFocus = FocusNode();
  final List<String> _suggestions = [];
  late final MapModel? _initialAddr;
  late final List<String> _abbre;
  late final List<String> _abbreInFull;

  List<String> _searchWords = [];
  MapModel? _selectedAddr;
  Timer? _cameraMoveTimer;
  GoogleMapController? _controller;
  bool _returnPage = false;

  @override
  void initState() {
    _abbre = MapProperties.streetAbbreviations.keys.toList();
    _abbreInFull = MapProperties.streetAbbreviations.values.toList();
    _init();
    super.initState();
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _fieldFocus.dispose();
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  Future<void> _init() async {
    _initialAddr = widget.args[0];

    if (_initialAddr == null) {
      final location = DataStore().locationData;
      if (location == null) return;
      _selectedAddr = await _getAddr(location.latitude!, location.longitude!);
    } else {
      _selectedAddr = _initialAddr;
    }
    if (mounted) setState(() {});
  }

  Future<MapModel> _getAddr(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng, localeIdentifier: "en");
    final main = placemarks.first;
    final addr = "${main.street}, ${main.postalCode}, ${main.country}".replaceAll(", ,", ",");

    return MapModel(addr: addr, lat: lat, lng: lng);
  }

  Future<MapModel?> _getCords(String addr) async {
    try {
      final locations = await locationFromAddress(addr, localeIdentifier: "en");
      final lat = locations.first.latitude;
      final lng = locations.first.longitude;

      return MapModel(addr: addr, lat: lat, lng: lng);
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> _getSuggestions(String addr) async {
    int matches(String result) {
      int count = 0;

      for (var word in _searchWords) {
        final index = _abbre.indexWhere((e) => e == word);
        if (index != -1) {
          if (result.contains(_abbre[index]) || result.contains(_abbreInFull[index])) count++;
        }

        if (result.contains(word)) count++;
      }

      return count;
    }

    Future<void> buildSuggestionsOnMatches(predictions, int reqMatch) async {
      for (final location in predictions) {
        if (_suggestions.length >= 8) break;

        final addr = location.fullText;

        final matchCount = matches(addr);
        if (matchCount != reqMatch) continue;

        final addrExist = _suggestions.any((element) => element == addr);
        if (addrExist) continue;

        _suggestions.add(addr);
        if (mounted) setState(() {});
      }
    }

    try {
      final result = await _googlePlace.findAutocompletePredictions(addr, countries: ["SG"], newSessionToken: false);
      _searchWords = addr.trim().replaceAll(",", "").split(" ");
      _suggestions.clear();

      for (int i = _searchWords.length; i > 0; i--) {
        if (_suggestions.length >= 8) break;
        await buildSuggestionsOnMatches(result.predictions, i);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void _onMapCreated(GoogleMapController controller) => setState(() {
        _controller = controller;
        _controller?.setMapStyle(DataStore().mapTheme);
      });

  Future<void> _onCameraMove(CameraPosition position) async => _cameraMoveTimer = Timer(const Duration(milliseconds: 200), () async {
        if (!_cameraMoveTimer!.isActive) {
          final lat = position.target.latitude;
          final lng = position.target.longitude;
          _fieldController.clear();
          _selectedAddr = await _getAddr(lat, lng);
          if (mounted) setState(() {});
        }
      });

  Future<void> _onAddrSelect(String addr) async {
    _selectedAddr = await _getCords(addr);
    _fieldFocus.unfocus();
    await _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(_selectedAddr!.lat, _selectedAddr!.lng), Configs.mapZoomLevel));
    if (mounted) setState(() {});
  }

  Future<void> _onFieldChanged(String value) async {
    if (value.length >= 3) {
      await _getSuggestions(value);
    } else if (_suggestions.isNotEmpty) {
      _suggestions.clear();
      if (mounted) setState(() {});
    }
  }

  void _onSubmit() async {
    if (_returnPage) return;

    setState(() => _returnPage = true);
    widget.args[1](_selectedAddr ?? _initialAddr);
    await Future.delayed(const Duration(milliseconds: 300)).then((_) => Navigation.pop(context));
  }

  void _onBack() async {
    if (_returnPage) return;

    setState(() => _returnPage = true);
    widget.args[1](_initialAddr);
    await Future.delayed(const Duration(milliseconds: 300)).then((_) => Navigation.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        key: _scaffoldKey,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _floatingBtn(),
        body: _body(),
      ),
    );
  }

  Widget _floatingBtn() => KeyboardVisibilityBuilder(
        builder: (_, isKeyboardVisible) => Visibility(
          visible: !isKeyboardVisible,
          child: FloatingActionButton.extended(
            heroTag: "FAB",
            elevation: 0,
            onPressed: _onSubmit,
            label: Row(
              children: const [
                Icon(Icons.location_on_rounded, color: PeanutTheme.almostBlack),
                SizedBox(width: 10),
                Text(
                  "Confirm Location",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _body() => Stack(
        children: [
          Column(
            children: [
              Expanded(child: _map()),
              _searchField(),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            child: _backBtn(),
          ),
        ],
      );

  Widget _backBtn() => Container(
        decoration: BoxDecoration(
          color: PeanutTheme.almostBlack.withOpacity(0.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: BackButton(
          onPressed: _onBack,
          color: PeanutTheme.white,
        ),
      );

  Widget _map() => SizedBox(
        width: double.infinity,
        child: _selectedAddr == null
            ? CommonUtils.loadingIndicator()
            : Stack(
                alignment: Alignment.center,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(_selectedAddr!.lat, _selectedAddr!.lng), zoom: Configs.mapZoomLevel),
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    zoomControlsEnabled: false,
                    buildingsEnabled: false,
                    indoorViewEnabled: false,
                    liteModeEnabled: false,
                    mapToolbarEnabled: false,
                    trafficEnabled: false,
                    onMapCreated: _onMapCreated,
                    onCameraMove: _onCameraMove,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                  if (_controller != null) const Icon(Icons.location_pin, color: PeanutTheme.almostBlack),
                ],
              ),
      );

  Widget _searchField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _selectedAddress(),
            if (Configs.enableSuggestions) _locationField(),
            if (Configs.enableSuggestions) _suggestionsBox(),
            KeyboardVisibilityBuilder(
              builder: (_, isKeyboardVisible) => Visibility(
                visible: !isKeyboardVisible,
                child: const SizedBox(height: 75),
              ),
            ),
          ],
        ),
      );

  Widget _locationField() => Hero(
        tag: "quest_location",
        child: Material(
          type: MaterialType.transparency,
          child: PeanutTextFormField(
            controller: _fieldController,
            label: "Search Location",
            focus: _fieldFocus,
            enableTitleCase: true,
            onChange: _onFieldChanged,
            suffixIcon: Visibility(
              visible: _fieldController.text.isNotEmpty,
              child: IconButton(
                onPressed: () {
                  _fieldController.clear();
                  _suggestions.clear();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.clear),
              ),
            ),
          ),
        ),
      );

  Widget _selectedAddress() => Container(
        key: Key(_selectedAddr?.addr ?? ""),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: PeanutTheme.primaryColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(300),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: PeanutTheme.almostBlack),
            const SizedBox(width: 10),
            Expanded(child: Text(_selectedAddr?.addr ?? "")),
          ],
        ),
      );

  Widget _suggestionsBox() {
    final list = _suggestions;
    if (list.isEmpty) return const SizedBox.shrink();

    final patternList = _searchWords
        .map((e) => EasyRichTextPattern(
              targetString: e,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ))
        .toList();

    for (var word in _searchWords) {
      final index = _abbre.indexWhere((abbr) => word == abbr);
      if (index != -1) {
        patternList.add(EasyRichTextPattern(
          targetString: _abbreInFull[index],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      }
    }

    return Container(
      constraints: BoxConstraints(minHeight: 100, maxHeight: MediaQuery.of(context).size.height * 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: PeanutTheme.backGroundColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: ListView.builder(
        key: Key(list.map((e) => e).toString()),
        padding: const EdgeInsets.all(0),
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (_, index) => Material(
          child: InkWell(
            highlightColor: PeanutTheme.primaryColor.withOpacity(0.5),
            onTap: () async => await _onAddrSelect(list[index]),
            child: Container(
              key: Key(list[index]),
              width: double.infinity,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: PeanutTheme.greyDivider, width: 0.5))),
              padding: const EdgeInsets.all(20),
              child: EasyRichText(
                list[index],
                caseSensitive: false,
                patternList: patternList,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
