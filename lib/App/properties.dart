import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Services/authentication_service.dart';
import 'package:peanut/Ui/Map/peanut_map.dart';
import 'package:peanut/Ui/Messenger/messenger.dart';
import 'package:peanut/Ui/Quests/quest_list.dart';

class Properties {
  static Properties? _instance;
  Properties._();
  factory Properties() => _instance ??= Properties._();

  late final String env;

  void init() {
    navigationBarIndex = ValueNotifier(0);
    navigationQueue = [0];
  }

  static void dispose() {
    navigationBarIndex.dispose();
  }

  static late ValueNotifier<int> navigationBarIndex;
  static late List<int> navigationQueue;
  static bool warnQuitApp = false;

  static changeTab(int tab) {
    navigationBarIndex.value = tab;
    navigationQueue.add(tab);
  }

  static reset() {
    navigationBarIndex.value = 0;
    navigationQueue.clear();
  }

  static Future<bool> onBack(BuildContext context) async {
    if (navigationQueue.isNotEmpty) {
      navigationQueue.removeLast();
      navigationBarIndex.value = navigationQueue.isNotEmpty ? navigationQueue.last : 0;
      return false;
    }
    return true;
  }

  static final Map<String, dynamic> _navigationScreens = {
    "Map": {
      "appBar": AppBar(),
      "screen": const PeanutMap(),
      "icon": FontAwesomeIcons.mapLocation,
    },
    "Messages": {
      "appBar": AppBar(
        title: const Text("Messages"),
        backgroundColor: PeanutTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      "screen": const Messenger(),
      "icon": FontAwesomeIcons.solidMessage,
    },
    "Quests": {
      "appBar": AppBar(
        title: const Text("Quests"),
        backgroundColor: PeanutTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      "screen": QuestList(),
      "icon": FontAwesomeIcons.listCheck,
    },
    "Profile": {
      "appBar": AppBar(
        title: const Text("Profile"),
        backgroundColor: PeanutTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      "screen": const TextButton(
        onPressed: AuthenticationService.logout,
        child: Text("LOG OUT"),
      ),
      "icon": FontAwesomeIcons.solidUser,
    }
  };
  static List<AppBar> get appBars => _navigationScreens.values.map<AppBar>((e) => e["appBar"]).toList();
  static List<Widget> get screens => _navigationScreens.values.map<Widget>((e) => e["screen"]).toList();
  static List<IconData> get icons => _navigationScreens.values.map<IconData>((e) => e["icon"]).toList();
  static List<String> get titles => _navigationScreens.keys.toList();
}

class MapProperties {
  static const streetAbbreviations = {
    "Ably": "Assembly",
    "Admin": "Administration",
    "Apt": "Apartment",
    "Ave": "Avenue",
    "Bldg": "Building",
    "Blk": "Block",
    "Blvd": "Boulevard",
    "Br": "Branch",
    "Bt": "Bukit",
    "Budd": "Buddhist",
    "Cath": "Cathedral",
    "Cc": "Community Club",
    "Chbrs": "Chambers",
    "Cine": "Cinema",
    "Cl": "Close",
    "Clubhse": "Clubhouse",
    "Condo": "Condominium",
    "Cp": "Carpark",
    "Cplx": "Complex",
    "Cres": "Crescent",
    "Ctr": "Centre",
    "Ctrl": "Central",
    "Cwealth": "CommonWealth",
    "Dept": "Department",
    "Div": "Division",
    "Dr": "Drive",
    "Edn": "Education",
    "Env": "Environment",
    "Est": "Estate",
    "Eway": "Expressway",
    "Fb": "Food Bridge",
    "Fc": "Food Centre",
    "Fty": "Factory",
    "Gdn": "Garden",
    "Gdns": "Gardens",
    "Govt": "Government",
    "Gr": "Grove",
    "Hosp": "Hospital",
    "Hq": "Headquarter",
    "Hse": "House",
    "Hts": "Heights",
    "Ind": "Industrial",
    "Inst": "Institute",
    "Instn": "Institution",
    "Intl": "International",
    "Jc": "Junior College",
    "Jln": "Jalan",
    "Jnr": "Junior",
    "Kg": "Kampong",
    "Lib": "Library",
    "Lk": "Link",
    "Lor": "Lorong",
    "Mai": "Maisonette",
    "Man": "Mansion",
    "Meth": "Methodist",
    "Min": "Ministy",
    "Mkt": "Market",
    "Mt": "Mount",
    "Natl": "National",
    "Nth": "North",
    "Pk": "Park",
    "Pl": "Place",
    "Pri": "Primary",
    "Pt": "Point",
    "Rd": "Road",
    "Sch": "School",
    "Sec": "Secondary",
    "Sg": "Singapore",
    "Sq": "Square",
    "St": "Street",
    "St.": "Saint",
    "Sth": "South",
    "Stn": "Station",
    "Tc": "Town Council",
    "Ter": "Terrace",
    "Tg": "Tanjong",
    "Upp": "Upper",
  };
}
