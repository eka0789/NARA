import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/notifications/device_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

/// The reminder scheduler computes fire times with `tz.local`; the resolver
/// must therefore return a zone that mirrors the device clock — either the
/// exact IANA zone when the OS reports one, or a same-offset stand-in, and
/// UTC only when nothing matches.
void main() {
  test('valid IANA zone names are used verbatim', () {
    final loc = resolveDeviceTimeZone(reportedZoneName: 'Asia/Jakarta');
    expect(loc.name, 'Asia/Jakarta');
  });

  test('short/Windows-style names fall back to offset matching', () {
    // Android reports abbreviations like "WIB" which the tz database does
    // not know — the resolver must still land on a +07:00 zone.
    final loc = resolveDeviceTimeZone(
      reportedZoneName: 'WIB',
      deviceUtcOffset: const Duration(hours: 7),
    );
    final now = tz.TZDateTime.now(loc);
    expect(now.timeZoneOffset, const Duration(hours: 7));
  });

  test('partial-hour offsets resolve (e.g. India +05:30)', () {
    final loc = resolveDeviceTimeZone(
      reportedZoneName: 'IST',
      deviceUtcOffset: const Duration(hours: 5, minutes: 30),
    );
    final now = tz.TZDateTime.now(loc);
    expect(now.timeZoneOffset, const Duration(hours: 5, minutes: 30));
  });

  test('preferred match holds its offset for a year (no DST drift)', () {
    final loc = resolveDeviceTimeZone(
      reportedZoneName: 'WIB',
      deviceUtcOffset: const Duration(hours: 7),
    );
    final now = tz.TZDateTime.now(loc);
    for (final span in const [Duration(days: 182), Duration(days: 365)]) {
      expect(now.add(span).timeZoneOffset, const Duration(hours: 7));
    }
  });

  test('unmatchable offset degrades to UTC instead of throwing', () {
    final loc = resolveDeviceTimeZone(
      reportedZoneName: 'Nowhere/Nothing',
      deviceUtcOffset: const Duration(minutes: 37),
    );
    expect(loc.name, 'UTC');
  });

  test('no-argument call matches the host clock', () {
    final device = DateTime.now();
    final loc = resolveDeviceTimeZone(now: device);
    final inZone = tz.TZDateTime.from(device.toUtc(), loc);
    expect(inZone.timeZoneOffset, device.timeZoneOffset);
  });
}
