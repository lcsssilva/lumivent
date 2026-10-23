import 'common_strings.dart';

class CommonStringsEn extends CommonStrings {
  const CommonStringsEn();

  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get remove => 'Remove';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Try again';
  @override
  String get details => 'Details';
  @override
  String get technicalDetails => 'Technical details';
  @override
  String get none => 'None';
  @override
  String get before => 'Before';
  @override
  String get after => 'After';
  @override
  String get configWriteFailed =>
      'Could not save your changes. Check the configuration folder permissions and available disk space.';
  @override
  String groupName(int group) => 'Group $group';
}
