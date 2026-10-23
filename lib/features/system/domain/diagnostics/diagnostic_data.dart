/// Technical values behind a check; the UI translates and composes the text.
/// Each check id has its own subtype, so the presentation reads typed fields
/// instead of casting map entries. Checks built outside this module (the
/// runtime checks) extend it with their own subtype.
abstract class DiagnosticData {
  const DiagnosticData();
}
