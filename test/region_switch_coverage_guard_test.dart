import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/screens/map/widgets/property_map_view.dart';

// [RegionSwitchCoverageGuard] là phần LOGIC THUẦN (generation-token
// suppression) tách khỏi [PropertyMapView] chính vì lý do có thể test được
// pure Dart mà không cần platform channel MapLibre thật (không mô phỏng
// được trong `flutter_test`). Test 6 case bắt buộc theo yêu cầu race-
// condition banner: explicit switch (2 chiều), stale callback sau switch,
// explicit switch hoàn tất, pan thật ra ngoài sau switch, pan trở vào.
void main() {
  group('RegionSwitchCoverageGuard', () {
    test(
      '1) explicit HCM → Hà Nội: intermediate/outside camera points during '
      'the flight never flip the banner on',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(1);

        // Camera bay qua nhiều điểm trung gian, tất cả đều "ngoài" theo
        // logic active-region CŨ (nếu không suppress sẽ bật banner sai).
        guard.onCameraMove(isOutsideCoverage: true);
        guard.onCameraMove(isOutsideCoverage: true);
        guard.onCameraMove(isOutsideCoverage: true);

        expect(guard.isOutsideCoverage, isFalse);
      },
    );

    test(
      '2) explicit Hà Nội → HCM: same suppression holds regardless of '
      'switch direction',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(7);

        guard.onCameraMove(isOutsideCoverage: true);
        guard.onCameraMove(isOutsideCoverage: true);

        expect(guard.isOutsideCoverage, isFalse);
      },
    );

    test(
      '3) a stale camera callback arriving AFTER the explicit switch has '
      'fully ended does not resurrect the banner, as long as it belongs to '
      'the generation that just ended (i.e. genuinely reflects a point '
      'inside the destination region — the real defense is that endExplicit'
      'Switch is the only place allowed to move isOutsideCoverage away from '
      'false right after a switch, not a timer)',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(3);
        guard.endExplicitSwitch(3, isOutsideCoverage: false);
        expect(guard.isOutsideCoverage, isFalse);

        // A late callback belonging to a NEWER, still-in-flight explicit
        // switch generation (4) must not be affected by anything left over
        // from generation 3 — simulates: user taps HCM (gen 3, completes),
        // then immediately taps Hà Nội again (gen 4) while a stale gen-3
        // camera event is still in the event queue.
        guard.beginExplicitSwitch(4);
        // Stale event nominally "for gen 3" has no way to reach the guard
        // except through onCameraMove, which is generation-agnostic by
        // design — it is blocked purely because suppression is active for
        // gen 4, regardless of which generation the caller thinks it's
        // reporting for.
        guard.onCameraMove(isOutsideCoverage: true);
        expect(guard.isOutsideCoverage, isFalse);
      },
    );

    test(
      '4) explicit switch fully completes → banner is false and suppression '
      'is lifted (organic onCameraMove works normally again afterwards)',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(1);
        guard.endExplicitSwitch(1, isOutsideCoverage: false);

        expect(guard.isOutsideCoverage, isFalse);
        expect(guard.isSuppressing, isFalse);
      },
    );

    test(
      '5) after an explicit switch ends, the user panning truly outside '
      'coverage makes the banner appear normally (organic tracking, not '
      'permanently disabled)',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(1);
        guard.endExplicitSwitch(1, isOutsideCoverage: false);

        guard.onCameraMove(isOutsideCoverage: true);
        expect(guard.isOutsideCoverage, isTrue);
      },
    );

    test('6) panning back inside coverage clears the banner again', () {
      final guard = RegionSwitchCoverageGuard();
      guard.beginExplicitSwitch(1);
      guard.endExplicitSwitch(1, isOutsideCoverage: false);
      guard.onCameraMove(isOutsideCoverage: true);
      expect(guard.isOutsideCoverage, isTrue);

      guard.onCameraMove(isOutsideCoverage: false);
      expect(guard.isOutsideCoverage, isFalse);
    });

    test(
      'endExplicitSwitch with a stale (superseded) generation is a no-op — '
      'does not touch isOutsideCoverage or clear the newer suppression',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(1);
        // A second, newer switch starts before the first one's completion
        // code runs (e.g. user double-tapped the region buttons).
        guard.beginExplicitSwitch(2);

        // Generation-1's completion code finally runs (stale) — must be
        // ignored entirely: does not clear suppression (still belongs to
        // gen 2) and does not set isOutsideCoverage.
        guard.endExplicitSwitch(1, isOutsideCoverage: true);
        expect(guard.isSuppressing, isTrue);
        expect(guard.isOutsideCoverage, isFalse);

        // Only generation-2's own completion is allowed to finalize.
        guard.endExplicitSwitch(2, isOutsideCoverage: false);
        expect(guard.isSuppressing, isFalse);
        expect(guard.isOutsideCoverage, isFalse);
      },
    );

    test(
      'cancelSuppression only clears suppression for a matching generation, '
      'and never touches isOutsideCoverage (used on switch failure/early '
      'return, where there is no valid destination point to report)',
      () {
        final guard = RegionSwitchCoverageGuard();
        guard.beginExplicitSwitch(5);
        guard.cancelSuppression(999); // wrong generation — no-op
        expect(guard.isSuppressing, isTrue);

        guard.cancelSuppression(5);
        expect(guard.isSuppressing, isFalse);
        expect(guard.isOutsideCoverage, isFalse); // untouched, stays default
      },
    );

    test('organic camera moves (no explicit switch) update the banner live', () {
      final guard = RegionSwitchCoverageGuard();
      expect(guard.isSuppressing, isFalse);

      guard.onCameraMove(isOutsideCoverage: true);
      expect(guard.isOutsideCoverage, isTrue);

      guard.onCameraMove(isOutsideCoverage: false);
      expect(guard.isOutsideCoverage, isFalse);
    });
  });
}
