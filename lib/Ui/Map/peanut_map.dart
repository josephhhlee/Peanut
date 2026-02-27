import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/properties.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/quest_model.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Ui/Quests/quest_page.dart';
import 'package:peanut/Ui/Quests/sorting.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/Utils/scroll_utils.dart';
import 'package:peanut/ViewModels/peanut_map_viewmodel.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PeanutMap extends StatefulWidget {
  const PeanutMap({super.key});

  @override
  State<PeanutMap> createState() => _PeanutMapState();
}

class _PeanutMapState extends State<PeanutMap> {
  final _viewModel = PeanutMapViewModel();
  final _panelController = PanelController();

  @override
  void initState() {
    _viewModel.init(_refresh);
    super.initState();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_panelController.isPanelOpen || _viewModel.subQuestList.isNotEmpty) {
          _panelController.close();
          _viewModel.clearSelectedMarker();
          return false;
        }
        if (Properties.navigationQueue.isEmpty && !Properties.warnQuitApp) {
          CommonUtils.toast(context, "Press back again to exit");
          Properties.warnQuitApp = true;
          return false;
        }
        return true;
      },
      child: PortalTarget(
        visible: true,
        portalFollower: _SubQuestList(viewModel: _viewModel),
        anchor: const Aligned(
          target: Alignment.bottomCenter,
          follower: Alignment.bottomCenter,
          offset: Offset(0, -120),
        ),
        child: _body(),
      ),
    );
  }

  Widget _body() => SlidingUpPanel(
        controller: _panelController,
        header: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.center,
          child: Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(color: PeanutTheme.white.withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
          ),
        ),
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: 0,
        color: PeanutTheme.almostBlack,
        onPanelSlide: (position) => _viewModel.clearSelectedMarker(),
        borderRadius: BorderRadius.circular(20),
        panel: _NearbyQuests(
          key: Key(_viewModel.fullQuestList.map((e) => e.toJson()).toString()),
          viewModel: _viewModel,
        ),
        body: _panelBody(),
      );

  Widget _panelBody() => Stack(
        alignment: Alignment.center,
        children: [
          _map(),
          if (!_viewModel.initMarkers) CommonUtils.loadingIndicator(),
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: PeanutTheme.almostBlack.withOpacity(0.7),
              ),
              child: CommonUtils.currentUserPeanutCurrency(color: PeanutTheme.white),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 70,
            child: TextButton(
              onPressed: () => _panelController.open(),
              style: TextButton.styleFrom(
                backgroundColor: PeanutTheme.almostBlack.withOpacity(0.6),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(100))),
                padding: const EdgeInsets.all(10),
              ),
              child: const Text(
                "Nearby Quests",
                style: TextStyle(color: PeanutTheme.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );

  Widget _map() {
    final location = DataStore().locationData;
    final lat = location?.latitude;
    final lng = location?.longitude;

    return GestureDetector(
      onPanDown: (_) {
        _panelController.close();
        FocusScope.of(context).unfocus();
      },
      child: GoogleMap(
        padding: _viewModel.mapController == null ? EdgeInsets.zero : const EdgeInsets.only(top: 100),
        initialCameraPosition: CameraPosition(target: LatLng(lat!, lng!), zoom: Configs.mapZoomLevel),
        markers: _viewModel.markers,
        mapType: MapType.normal,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        zoomGesturesEnabled: false,
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        tiltGesturesEnabled: false,
        buildingsEnabled: false,
        indoorViewEnabled: false,
        liteModeEnabled: false,
        mapToolbarEnabled: false,
        trafficEnabled: false,
        onTap: (_) => _viewModel.clearSelectedMarker(),
        onMapCreated: _viewModel.onMapCreated,
        onCameraMove: _viewModel.manager?.onCameraMove,
        onCameraIdle: _viewModel.manager?.updateMap,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
      ),
    );
  }
}

class _NearbyQuests extends StatefulWidget {
  final PeanutMapViewModel viewModel;

  const _NearbyQuests({super.key, required this.viewModel});

  @override
  State<_NearbyQuests> createState() => _NearbyQuestsState();
}

class _NearbyQuestsState extends State<_NearbyQuests> {
  final _searchController = TextEditingController();
  final List<Quest> _selectedQuestList = [];
  final List<String> _searchWords = [];

  String _selectedSort = "Distance;Ascending";

  @override
  void initState() {
    widget.viewModel.fullQuestList.sort(_buildComparator());
    _selectedQuestList.addAll(widget.viewModel.fullQuestList);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String text) async {
    if (text.isEmpty) return _onClearSearch();

    _selectedQuestList.clear();
    _searchWords.clear();
    _searchWords.addAll(text.trim().replaceAll(",", "").toLowerCase().split(" "));

    for (Quest quest in widget.viewModel.fullQuestList) {
      final user = await DataStore().getUser(quest.creator);
      final searchable = "${user?.displayName ?? ""} ${quest.mapModel!.addr} ${quest.title}";
      final searchableWords = searchable.trim().replaceAll(",", "").toLowerCase().split(" ");

      if (_searchWords.every((search) => searchableWords.any((searchable) => search == searchable))) _selectedQuestList.add(quest);
    }

    if (mounted) setState(() {});
  }

  void _onClearSearch() {
    _searchWords.clear();
    _searchController.clear();
    _selectedQuestList.clear();
    _selectedQuestList.addAll(widget.viewModel.fullQuestList);

    if (mounted) setState(() {});
  }

  void _onSort(String selectedSort) {
    _selectedSort = selectedSort;
    _buildComparator();
    widget.viewModel.fullQuestList.sort(_buildComparator());
    _selectedQuestList.sort(_buildComparator());
    if (mounted) setState(() {});
  }

  int Function(MiniQuest, MiniQuest)? _buildComparator() {
    final isAsc = _selectedSort.split(";")[1].contains("Asc");

    double dist(MiniQuest quest) {
      final currentUserLocation = DataStore().locationData!;
      return Geolocator.distanceBetween(currentUserLocation.latitude!, currentUserLocation.longitude!, quest.mapModel!.lat, quest.mapModel!.lng);
    }

    if (_selectedSort.contains("Recently Created")) {
      return (a, b) {
        int compare = isAsc ? a.createdOn.compareTo(b.createdOn) : b.createdOn.compareTo(a.createdOn);
        if (compare != 0) return compare;
        int compare2 = (b.takenOn ?? 0).compareTo((a.takenOn ?? 0));
        if (compare2 != 0) return compare2;
        int compare3 = dist(a).compareTo(dist(b));
        if (compare3 != 0) return compare2;
        return b.rewards.compareTo(a.rewards);
      };
    } else if (_selectedSort.contains("Recently Taken")) {
      return (a, b) {
        int compare = isAsc ? (a.takenOn ?? 0).compareTo((b.takenOn ?? 0)) : (b.takenOn ?? 0).compareTo((a.takenOn ?? 0));
        if (compare != 0) return compare;
        int compare2 = b.createdOn.compareTo(a.createdOn);
        if (compare2 != 0) return compare2;
        int compare3 = dist(a).compareTo(dist(b));
        if (compare3 != 0) return compare2;
        return b.rewards.compareTo(a.rewards);
      };
    } else if (_selectedSort.contains("Distance")) {
      return (a, b) {
        int compare = isAsc ? dist(a).compareTo(dist(b)) : dist(b).compareTo(dist(a));
        if (compare != 0) return compare;
        int compare2 = b.createdOn.compareTo(a.createdOn);
        if (compare2 != 0) return compare2;
        int compare3 = (b.takenOn ?? 0).compareTo((a.takenOn ?? 0));
        if (compare3 != 0) return compare2;
        return b.rewards.compareTo(a.rewards);
      };
    } else if (_selectedSort.contains("Rewards")) {
      return (a, b) {
        int compare = isAsc ? a.rewards.compareTo(b.rewards) : b.rewards.compareTo(a.rewards);
        if (compare != 0) return compare;
        int compare2 = b.createdOn.compareTo(a.createdOn);
        if (compare2 != 0) return compare2;
        int compare3 = (b.takenOn ?? 0).compareTo((a.takenOn ?? 0));
        if (compare3 != 0) return compare2;
        return dist(a).compareTo(dist(b));
      };
    } else {
      return (a, b) {
        int compare = b.createdOn.compareTo(a.createdOn);
        if (compare != 0) return compare;
        int compare2 = (b.takenOn ?? 0).compareTo((a.takenOn ?? 0));
        if (compare2 != 0) return compare2;
        int compare3 = dist(a).compareTo(dist(b));
        if (compare3 != 0) return compare2;
        return b.rewards.compareTo(a.rewards);
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: _searchBar()),
                _sortBtn(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Flexible(child: _questListContents()),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sortBtn() => IconButton(
        tooltip: "Sort",
        onPressed: () async {
          FocusScope.of(context).unfocus();
          await SortingSheet(
            context: context,
            onSort: _onSort,
            selectedSort: _selectedSort,
            excludeRecentTaken: true,
          ).push();
        },
        splashRadius: 20,
        icon: const Icon(
          FontAwesomeIcons.sort,
          color: PeanutTheme.primaryColor,
        ),
      );

  Widget _searchBar() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 55,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: TextField(
            autofocus: false,
            controller: _searchController,
            onChanged: (value) async => await _onSearch(value),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: "Search Quest..",
              suffixIcon: Visibility(
                visible: _searchController.text.isNotEmpty,
                child: IconButton(
                  onPressed: _onClearSearch,
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _questListContents() => DisableScrollGlow(
        child: Scrollbar(
          child: ListView.builder(
            key: Key(_selectedQuestList.map((e) => e.id).toString()),
            padding: EdgeInsets.zero,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _selectedQuestList.length,
            itemBuilder: (context, index) => _questCard(_selectedQuestList[index], index),
          ),
        ),
      );

  Widget _questCard(MiniQuest quest, int index) {
    Widget main(NutUser? user) => Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: PeanutTheme.almostBlack, width: 3))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonUtils.userImage(context: context, user: user, size: 65),
              const SizedBox(width: 15),
              Flexible(fit: FlexFit.tight, child: _questDetails(quest, user)),
            ],
          ),
        );

    return Material(
      key: Key(quest.id),
      child: CachedUserData(
        uid: quest.creator,
        builder: (user) => InkWell(
          highlightColor: PeanutTheme.primaryColor.withOpacity(0.5),
          onTap: () => user == null ? false : Navigation.push(context, QuestPage.routeName, args: [user, quest.id]),
          child: main(user),
        ),
      ),
    );
  }

  Widget _questDetails(MiniQuest quest, NutUser? user) {
    final patternList = _searchWords
        .map((e) => EasyRichTextPattern(
              targetString: e,
              style: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.black),
            ))
        .toList();

    Widget name() => EasyRichText(
          user?.displayName ?? "",
          caseSensitive: false,
          patternList: patternList,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          defaultStyle: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.primaryColor),
        );

    Widget title() => EasyRichText(
          quest.title!,
          caseSensitive: false,
          patternList: patternList,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

    Widget address() => Row(
          children: [
            const Icon(Icons.location_on_rounded, color: PeanutTheme.almostBlack, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: EasyRichText(
                quest.mapModel!.addr,
                caseSensitive: false,
                patternList: patternList,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                defaultStyle: const TextStyle(color: PeanutTheme.grey),
              ),
            ),
          ],
        );

    Widget distance() => Text(
          CommonUtils.getDistance(quest.mapModel!.lat, quest.mapModel!.lng),
          style: const TextStyle(color: PeanutTheme.grey),
        );

    Widget reward() => Row(
          children: [
            const Text("Rewards"),
            const SizedBox(width: 5),
            Expanded(
              child: CommonUtils.peanutCurrency(
                value: quest.rewards.toString(),
                color: PeanutTheme.primaryColor,
                textSize: 14,
                iconSize: 70,
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        name(),
        title(),
        const SizedBox(height: 15),
        address(),
        distance(),
        const SizedBox(height: 15),
        reward(),
      ],
    );
  }
}

class _SubQuestList extends StatefulWidget {
  final PeanutMapViewModel viewModel;

  const _SubQuestList({required this.viewModel});

  @override
  State<_SubQuestList> createState() => __SubQuestListState();
}

class __SubQuestListState extends State<_SubQuestList> {
  final List<Quest> _list = [];
  final Duration duration = const Duration(milliseconds: 300);
  Offset offset = const Offset(0, 1);

  @override
  void initState() {
    widget.viewModel.subListTrigger = _triggerSlide;
    super.initState();
  }

  void _slideUp() {
    setState(() => offset = const Offset(0, 0));
  }

  void _slideDown() {
    setState(() => offset = const Offset(0, 1));
  }

  void _triggerSlide(List<Quest> list) {
    _list.clear();
    _list.addAll(list);
    _slideDown();
    if (list.isNotEmpty) _slideUp();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: offset,
      duration: duration,
      curve: Curves.fastOutSlowIn,
      child: _list.isEmpty
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9, maxHeight: MediaQuery.of(context).size.height * 0.6),
                color: PeanutTheme.backGroundColor,
                child: DisableScrollGlow(
                  child: ListView.builder(
                    key: Key(_list.map((e) => e.id).toString()),
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    itemCount: _list.length,
                    itemBuilder: (context, index) => _questCard(_list[index]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _questCard(Quest quest) => CachedUserData(
        key: Key(quest.id),
        uid: quest.creator,
        builder: (user) => Material(
          child: InkWell(
            highlightColor: PeanutTheme.primaryColor.withOpacity(0.5),
            onTap: () => user == null ? false : Navigation.push(context, QuestPage.routeName, args: [user, quest]),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: PeanutTheme.greyDivider))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonUtils.userImage(context: context, user: user, size: 65),
                  const SizedBox(width: 15),
                  Flexible(fit: FlexFit.tight, child: _questDetails(quest, user)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _questDetails(Quest quest, NutUser? user) {
    Widget name() => Text(
          user?.displayName ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.darkOrange),
        );

    Widget title() => Text(
          quest.title!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

    Widget address() => Row(
          children: [
            const Icon(Icons.location_on_rounded, color: PeanutTheme.almostBlack, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                quest.mapModel!.addr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PeanutTheme.grey),
              ),
            ),
          ],
        );

    Widget distance() => Text(
          CommonUtils.getDistance(quest.mapModel!.lat, quest.mapModel!.lng),
          style: const TextStyle(color: PeanutTheme.grey),
        );

    Widget reward() => Row(
          children: [
            const Text(
              "Rewards",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: CommonUtils.peanutCurrency(
                value: quest.rewards.toString(),
                color: PeanutTheme.primaryColor,
                textSize: 14,
                iconSize: 70,
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        name(),
        title(),
        const SizedBox(height: 15),
        address(),
        distance(),
        const SizedBox(height: 15),
        reward(),
      ],
    );
  }
}
