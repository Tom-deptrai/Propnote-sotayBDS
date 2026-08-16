import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/state/app_state.dart';
import 'package:propnote/subscription/property_quota_policy.dart';

Property _propertyAt(AppState state, String id) {
  final now = DateTime(2026, 8, 16);
  final type = state.propertyTypeModels.first;
  return Property(
    id: id,
    title: 'BĐS $id',
    address: 'BĐS $id',
    areaId: state.areas.first.id,
    status: PropertyStatus.selling,
    price: 1e9,
    landArea: 50,
    propertyTypeId: type.id,
    propertyType: type.name,
    createdAt: now,
  );
}

void main() {
  group('PropertyQuotaPolicy.canCreateProperty — Free', () {
    test('0 BĐS → allowed', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: 0,
        ),
        isTrue,
      );
    });

    test('9 BĐS → allowed (10th is still free)', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: 9,
        ),
        isTrue,
      );
    });

    test('10 BĐS → blocked', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: 10,
        ),
        isFalse,
      );
    });

    test('quá 10 BĐS (vd. từng Pro rồi hết hạn) → vẫn blocked', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: 50,
        ),
        isFalse,
      );
    });
  });

  group('PropertyQuotaPolicy.canCreateProperty — Pro', () {
    test('0 BĐS → allowed', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: true,
          countedPropertyTotal: 0,
        ),
        isTrue,
      );
    });

    test('10 BĐS → allowed', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: true,
          countedPropertyTotal: 10,
        ),
        isTrue,
      );
    });

    test('100 BĐS → allowed (không giới hạn)', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: true,
          countedPropertyTotal: 100,
        ),
        isTrue,
      );
    });
  });

  group('PropertyQuotaPolicy + AppState — Thùng rác vẫn tính quota', () {
    test('10 BĐS tổng cộng, một phần trong Thùng rác → vẫn blocked cho tới khi '
        'xoá vĩnh viễn giải phóng quota', () async {
      final state = AppState();
      // Fixture AppState() khởi tạo sẵn vài property mock — reset về
      // trạng thái sạch bằng cách đếm tổng hiện có rồi thêm cho đủ 10.
      while (state.properties.length + state.trash.length < 10) {
        final id = 'quota-${state.properties.length + state.trash.length}';
        await state.addProperty(_propertyAt(state, id));
      }
      final beforeTotal = state.properties.length + state.trash.length;
      expect(beforeTotal, greaterThanOrEqualTo(10));
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: beforeTotal,
        ),
        isFalse,
      );

      // Xoá mềm một BĐS (vào Thùng rác) — tổng số không đổi, quota KHÔNG
      // được giải phóng.
      final firstId = state.properties.first.id;
      await state.deleteProperty(firstId);
      final afterSoftDeleteTotal = state.properties.length + state.trash.length;
      expect(afterSoftDeleteTotal, beforeTotal);
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: afterSoftDeleteTotal,
        ),
        isFalse,
      );

      // Xoá vĩnh viễn — tổng số giảm đúng 1 chỗ, giải phóng đúng 1 quota.
      await state.deletePermanently(firstId);
      final afterPermanentDeleteTotal =
          state.properties.length + state.trash.length;
      expect(afterPermanentDeleteTotal, beforeTotal - 1);

      // Tiếp tục xoá (mềm rồi vĩnh viễn) cho tới khi thật sự dưới giới
      // hạn Free — fixture ban đầu có thể đã có nhiều hơn 10 property
      // mock, nên "xoá đúng 1 cái" không phải lúc nào cũng đủ để mở lại
      // quota; assertion phải theo dõi đúng tổng số thực tế, không giả
      // định trước một con số cụ thể.
      while (state.properties.length + state.trash.length >=
          PropertyQuotaPolicy.freeLimit) {
        final id = state.properties.first.id;
        await state.deleteProperty(id);
        await state.deletePermanently(id);
      }
      final finalTotal = state.properties.length + state.trash.length;
      expect(finalTotal, lessThan(PropertyQuotaPolicy.freeLimit));
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: finalTotal,
        ),
        isTrue,
      );
    });
  });

  group('Pro hết hạn với dữ liệu vượt quota', () {
    test(
      'user từng Pro có 50 BĐS, subscription hết hạn (isPro=false) → dữ liệu '
      'hiện có vẫn dùng được (không phải xoá), nhưng tạo mới bị chặn',
      () {
        // "Dữ liệu vẫn dùng được" là tuyên bố về UI/CRUD (properties list vẫn
        // giữ nguyên 50 item, xem/sửa/xoá không phụ thuộc canCreateProperty)
        // — chỉ riêng hành động "tạo mới" mới bị policy này chặn.
        expect(
          PropertyQuotaPolicy.canCreateProperty(
            isPro: false,
            countedPropertyTotal: 50,
          ),
          isFalse,
        );
      },
    );

    test('xoá xuống dưới 10 → free user tạo thêm được tới giới hạn', () {
      expect(
        PropertyQuotaPolicy.canCreateProperty(
          isPro: false,
          countedPropertyTotal: 9,
        ),
        isTrue,
      );
    });
  });

  group('PropertyQuotaPolicy.remainingFreeSlots', () {
    test('Pro luôn trả về 0 (không hiển thị đếm ngược)', () {
      expect(
        PropertyQuotaPolicy.remainingFreeSlots(
          isPro: true,
          countedPropertyTotal: 3,
        ),
        0,
      );
    });

    test('Free còn 4 chỗ khi đã có 6', () {
      expect(
        PropertyQuotaPolicy.remainingFreeSlots(
          isPro: false,
          countedPropertyTotal: 6,
        ),
        4,
      );
    });

    test('Free đã đạt/vượt giới hạn → 0, không âm', () {
      expect(
        PropertyQuotaPolicy.remainingFreeSlots(
          isPro: false,
          countedPropertyTotal: 15,
        ),
        0,
      );
    });
  });
}
