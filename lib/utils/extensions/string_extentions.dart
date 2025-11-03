import 'package:path/path.dart' as path;

import '../constant.dart';

const int averageWordsPerMinute = 180;

extension StrExt on String {
  int getWordsCount() {
    return this.split(' ').length;
  }

  int getEstimatedTimeInMin() {
    return (this.getWordsCount() / averageWordsPerMinute).ceil();
  }

  String get getFileExtension => path.extension(Uri.parse(this).path);

  String get getFileNameWithoutExtension =>
      path.basenameWithoutExtension(Uri.parse(this).path);

  String get getFileName => path.basename(Uri.parse(this).path);

  String get getChatFileName =>
      path.basename(Uri.parse(this).path).replaceFirst("$CHAT_FILES%2F", "");
}
