import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/quest_model.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/Quests/quest_page.dart';
import 'package:peanut/Ui/Quests/sorting.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/Utils/scroll_utils.dart';

class QuestList extends StatelessWidget {
  QuestList({super.key});

  final _controller = PageController();
  final _selectedTab = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Column(
          children: [
            _tabs(context),
            Expanded(child: _contents(context)),
          ],
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context) => Row(
        children: [
          Expanded(child: _tab("Accepted", 0, context)),
          Expanded(child: _tab("Created", 1, context)),
        ],
      );

  Widget _tab(String title, int page, BuildContext context) => Container(
        color: PeanutTheme.primaryColor,
        child: ValueListenableBuilder(
          valueListenable: _selectedTab,
          builder: (_, value, __) => InkWell(
            onTap: () {
              _controller.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
              _selectedTab.value = page;
              FocusScope.of(context).unfocus();
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: value == page ? PeanutTheme.backGroundColor : PeanutTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PeanutTheme.almostBlack, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

  Widget _contents(BuildContext context) => PageView(
        scrollDirection: Axis.horizontal,
        controller: _controller,
        onPageChanged: (value) {
          _selectedTab.value = value;
          FocusScope.of(context).unfocus();
        },
        physics: const BouncingScrollPhysics(),
        pageSnapping: true,
        children: const [
          _QuestListTab(tab: "taken"),
          _QuestListTab(tab: "created"),
        ],
      );
}

class _QuestListTab extends StatefulWidget {
  final String tab;

  const _QuestListTab({required this.tab});

  @override
  State<_QuestListTab> createState() => __QuestListTabState();
}

class __QuestListTabState extends State<_QuestListTab> with AutomaticKeepAliveClientMixin<_QuestListTab> {
  final _searchController = TextEditingController();
  final List<MiniQuest> _questList = [];
  final List<MiniQuest> _selectedQuestList = [];
  final List<String> _searchWords = [];
  late final StreamSubscription<DocumentSnapshot> _questListener;

  String _selectedSort = "Recently Created;Descending";
  bool _initialised = false;

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _questListener.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _init() async {
    final uid = DataStore().currentUser!.uid;
    final ref = widget.tab == "taken" ? FirestoreService.userQuestListTakenDoc(uid) : FirestoreService.userQuestListCreatedDoc(uid);

    _questListener = ref.snapshots().listen((doc) {
      final map = doc.data() as Map;
      _questList.clear();
      _selectedQuestList.clear();
      map.forEach((key, value) => _questList.add(MiniQuest.fromMap(key, value)));
      _selectedQuestList.addAll(_questList);
      _onSort(_selectedSort);
      _initialised = true;
      if (mounted) setState(() {});
    });
  }

  Future<void> _onSearch(String text) async {
    if (text.isEmpty) return _onClearSearch();

    _selectedQuestList.clear();
    _searchWords.clear();
    _searchWords.addAll(text.trim().replaceAll(",", "").toLowerCase().split(" "));

    for (MiniQuest quest in _questList) {
      final user = await DataStore().getUser(widget.tab == "taken" ? quest.creator : quest.taker);
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
    _selectedQuestList.addAll(_questList);

    if (mounted) setState(() {});
  }

  void _onSort(String selectedSort) {
    _selectedSort = selectedSort;
    _buildComparator();
    _questList.sort(_buildComparator());
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
    super.build(context);
    if (!_initialised) return Center(child: CommonUtils.loadingIndicator(expand: true));

    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _searchBar()),
              _sortBtn(),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(child: _questListContents()),
        ],
      ),
    );
  }

  Widget _sortBtn() => IconButton(
        tooltip: "Sort",
        onPressed: () async {
          FocusScope.of(context).unfocus();
          await SortingSheet(context: context, onSort: _onSort, selectedSort: _selectedSort).push();
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

  Widget _questListContents() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DisableScrollGlow(
          child: ListView.builder(
            key: Key(_selectedQuestList.map((e) => e.id).toString()),
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
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: PeanutTheme.backGroundColor, width: 3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonUtils.userImage(context: context, user: user, size: 65),
                  const SizedBox(width: 15),
                  Flexible(fit: FlexFit.tight, child: _questDetails(quest, user)),
                ],
              ),
              if (widget.tab == "created" && quest.taker != null) _takerDetails(quest),
            ],
          ),
        );

    Widget statusLabel() {
      final visible = (widget.tab == "taken" && quest.status != QuestStatus.taken) || (widget.tab == "created" && quest.status != QuestStatus.untaken);

      return Visibility(
        visible: visible,
        child: Container(
          decoration: const BoxDecoration(
            color: PeanutTheme.darkOrange,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
          ),
          padding: const EdgeInsets.all(7),
          child: Text(
            quest.status.name,
            style: const TextStyle(color: PeanutTheme.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    return Material(
      key: Key(quest.id),
      child: CachedUserData(
        uid: quest.creator,
        builder: (user) => InkWell(
          highlightColor: PeanutTheme.primaryColor.withOpacity(0.5),
          onTap: () => user == null ? false : Navigation.push(context, QuestPage.routeName, args: [user, quest.id]),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              main(user),
              Positioned(
                bottom: 3,
                child: statusLabel(),
              ),
            ],
          ),
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

    Widget name() => widget.tab == "created"
        ? Text(
            user?.displayName ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.primaryColor),
          )
        : EasyRichText(
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

  Widget _takerDetails(MiniQuest quest) {
    final patternList = _searchWords
        .map((e) => EasyRichTextPattern(
              targetString: e,
              style: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.black),
            ))
        .toList();

    Widget details(NutUser? user) => Row(
          children: [
            CommonUtils.userImage(context: context, user: user, size: 65),
            const SizedBox(width: 15),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EasyRichText(
                  user?.displayName ?? "",
                  caseSensitive: false,
                  patternList: patternList,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  defaultStyle: const TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.primaryColor),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    elevation: 3,
                    backgroundColor: PeanutTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  onPressed: () => false,
                  child: const Text(
                    "Message",
                    style: TextStyle(color: PeanutTheme.almostBlack),
                  ),
                ),
              ],
            )),
          ],
        );

    return CachedUserData(
      uid: quest.taker!,
      builder: (user) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Quest Taker :",
              style: TextStyle(fontWeight: FontWeight.bold, color: PeanutTheme.almostBlack),
            ),
            const SizedBox(height: 10),
            details(user),
          ],
        ),
      ),
    );
  }
}
