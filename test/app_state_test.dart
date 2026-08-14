import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/state/app_state.dart';

void main() {
  test('marker scale is symmetric around the default and clamps safely', () {
    expect(
      AppState.markerScaleDefault - AppState.markerScaleMin,
      closeTo(AppState.markerScaleMax - AppState.markerScaleDefault, 1e-9),
    );

    final state = AppState();
    state.setMarkerScale(-1);
    expect(state.markerScale, AppState.markerScaleMin);
    state.setMarkerScale(99);
    expect(state.markerScale, AppState.markerScaleMax);
    state.resetMarkerScale();
    expect(state.markerScale, AppState.markerScaleDefault);
  });

  test('reorders property types and tags in AppState', () {
    final state = AppState();
    final firstType = state.propertyTypes.first;
    final firstTag = state.tagOptions.first;

    state.reorderPropertyTypes(0, state.propertyTypes.length - 1);
    state.reorderTagOptions(0, state.tagOptions.length - 1);

    expect(state.propertyTypes.last, firstType);
    expect(state.tagOptions.last, firstTag);
  });
}
