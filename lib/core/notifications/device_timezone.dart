import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

void _ensureDatabase() {
  if (_initialized) return;
  tzdata.initializeTimeZones();
  _initialized = true;
}

/// Picks the [tz.Location] that best matches this device's clock.
///
/// The package leaves `tz.local` at UTC until `setLocalLocation` is called,
/// so scheduling without this would fire reminders at UTC wall-clock time
/// (e.g. 15:00 WIB when the user asked for 08:00). The OS-reported zone
/// name is used when it is a valid IANA id — Android often reports short
/// names like "WIB" which the tz database does not know — otherwise the
/// database is scanned for a location whose current UTC offset matches the
/// device's, preferring one that holds that offset for the coming year so
/// scheduled reminders do not drift across DST changes.
tz.Location resolveDeviceTimeZone({
  DateTime? now,
  String? reportedZoneName,
  Duration? deviceUtcOffset,
}) {
  _ensureDatabase();
  final at = now ?? DateTime.now();
  final reported = (reportedZoneName ?? at.timeZoneName).trim();

  if (reported.isNotEmpty) {
    try {
      return tz.getLocation(reported);
    } on Object {
      // Short/Windows-style names ("WIB", "W. Europe Standard Time") are
      // not IANA ids — fall through to offset matching.
    }
  }

  final target = deviceUtcOffset ?? at.timeZoneOffset;
  final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
  tz.Location? fallback;
  for (final name in names) {
    final loc = tz.getLocation(name);
    final local = tz.TZDateTime.from(at.toUtc(), loc);
    if (local.timeZoneOffset != target) continue;
    if (_offsetStableForAYear(loc, local)) return loc;
    fallback ??= loc;
  }
  return fallback ?? tz.UTC;
}

/// True when the location holds its current offset for the next year.
bool _offsetStableForAYear(tz.Location loc, tz.TZDateTime local) {
  for (final span in const [
    Duration(days: 182),
    Duration(days: 365),
  ]) {
    if (local.add(span).timeZoneOffset != local.timeZoneOffset) {
      return false;
    }
  }
  return true;
}
