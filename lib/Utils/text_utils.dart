import 'package:flutter/services.dart';

class TextUtil {
  static String convertTitleCase(String text, {formatToOfAs = false, absolute = false}) {
    if (text.isEmpty) return "";
    var result = "";
    var resultList = [];
    var words = absolute ? text.toLowerCase().trim().split(" ") : text.trim().split(" ");
    for (var word in words) {
      var newWord = "${word[0].toUpperCase()}${word.substring(1)}";
      resultList.add(formatToOfAs && (word == "of" || word == "to" || word == "as") ? word : newWord);
    }
    result = resultList.isEmpty ? "" : resultList.join(" ");
    return result.isEmpty ? text.trim() : result.trim();
  }
}

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var hasSpacing = newValue.text.isNotEmpty ? newValue.text[newValue.text.length - 1] == " " : false;
    var text = TextUtil.convertTitleCase(newValue.text) + (hasSpacing ? " " : "");

    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase();

    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}
