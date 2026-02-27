import 'package:flutter/material.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/quest_model.dart';

class SortingSheet extends StatefulWidget {
  final BuildContext context;
  final String selectedSort;
  final bool excludeRecentTaken;
  final void Function(String selectedSort) onSort;

  const SortingSheet({super.key, required this.context, required this.onSort, required this.selectedSort, this.excludeRecentTaken = false});

  Future push() async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (BuildContext bottomSheetContext) => this,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
    );
  }

  @override
  State<SortingSheet> createState() => _SortingSheetState();
}

class _SortingSheetState extends State<SortingSheet> {
  late final List<String> sortingTypes;
  late List<MiniQuest> list;
  late String selectedSort;

  @override
  void initState() {
    sortingTypes = ["Recently Created;Ascending", if (!widget.excludeRecentTaken) "Recently Taken;Ascending", "Distance;Ascending", "Rewards;Ascending"];

    selectedSort = widget.selectedSort;

    if (selectedSort.contains("Desc")) {
      final sort = selectedSort.split(";")[0];
      sortingTypes[sortingTypes.indexWhere((sortType) => sortType.contains(sort))] = selectedSort;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title(),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(10),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: sortingTypes.map((sort) => fieldCard(sort)).toList()),
                ),
              ),
            ),
          ),
          buttons(),
        ],
      ),
    );
  }

  Widget fieldCard(String field) {
    final sortType = field.split(";");
    final selected = selectedSort.contains(sortType[0]);

    return GestureDetector(
      onTap: () async {
        if (selectedSort.contains(sortType[0]) && field.contains(";")) {
          var order = sortType[1].contains("Asc") ? "Descending" : "Ascending";
          selectedSort = "${sortType[0]};$order";
          sortingTypes[sortingTypes.indexOf(field)] = selectedSort;
        } else {
          selectedSort = field;
        }
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? PeanutTheme.primaryColor.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Text(
              sortType[0],
              style: const TextStyle(color: Colors.black, fontSize: 15),
            ),
            const Spacer(),
            Visibility(
              visible: selected && field.contains(";"),
              child: Icon(
                field.contains(";") && sortType[1].contains("Asc") ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                color: PeanutTheme.primaryColor,
              ),
            ),
            Text(
              selected && field.contains(";") ? sortType[1] : "",
              style: const TextStyle(color: PeanutTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget title() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30, left: 25),
      child: const Text(
        "Sort By",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buttons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(child: clearBtn()),
          const SizedBox(width: 10),
          Expanded(child: applyBtn()),
        ],
      ),
    );
  }

  Widget clearBtn() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: PeanutTheme.white,
        foregroundColor: PeanutTheme.primaryColor,
        side: const BorderSide(color: PeanutTheme.greyDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.all(15),
      ),
      onPressed: () async {
        Navigator.pop(context);
        selectedSort = "Recently Created;Descending";
        widget.onSort(selectedSort);
      },
      child: Container(
        alignment: Alignment.center,
        child: const Text(
          "Reset",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget applyBtn() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: PeanutTheme.primaryColor,
        foregroundColor: PeanutTheme.almostBlack,
        side: const BorderSide(color: PeanutTheme.greyDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.all(15),
      ),
      onPressed: () async {
        Navigator.pop(context);
        widget.onSort(selectedSort);
      },
      child: Container(
        alignment: Alignment.center,
        child: const Text(
          "Apply",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
