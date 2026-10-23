/// Strings shared by more than one area.
abstract class CommonStrings {
  const CommonStrings();

  String get cancel;
  String get save;
  String get remove;
  String get close;
  String get retry;
  String get details;
  String get technicalDetails;
  String get none;
  String get before;
  String get after;
  String get configWriteFailed;

  /// Default name of a fan group (group 0–3).
  String groupName(int group);
}
