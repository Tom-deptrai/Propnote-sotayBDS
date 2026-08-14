import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_document.dart';
import 'package:propnote/models/property_photo.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/screens/detail/property_detail_screen.dart';
import 'package:propnote/state/app_state.dart';
import 'package:propnote/widgets/document_photo.dart';
import 'package:propnote/widgets/full_screen_image_viewer.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createDetailScreen({
    required AppState state,
    required String propertyId,
  }) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(home: PropertyDetailScreen(propertyId: propertyId)),
    );
  }

  testWidgets('detail screen has no text overlay on hero SliverAppBar', (
    WidgetTester tester,
  ) async {
    final state = AppState();
    final property = state.propertyById('p1')!;

    await tester.pumpWidget(createDetailScreen(state: state, propertyId: 'p1'));
    await tester.pump();

    // Verify SliverAppBar has no title widget
    final sliverAppBarFinder = find.byType(SliverAppBar);
    expect(sliverAppBarFinder, findsOneWidget);
    final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
    expect(sliverAppBar.title, isNull);

    // Title and address are displayed in the body content below
    expect(find.text(property.title), findsOneWidget);
    expect(find.text(property.address), findsOneWidget);
  });

  testWidgets('tapping hero photo opens FullScreenImageViewer', (
    WidgetTester tester,
  ) async {
    final state = AppState();

    await tester.pumpWidget(createDetailScreen(state: state, propertyId: 'p1'));
    await tester.pump();

    // Tap on the hero photo in SliverAppBar
    final heroPhoto = find.descendant(
      of: find.byType(SliverAppBar),
      matching: find.byType(GestureDetector).first,
    );
    expect(heroPhoto, findsOneWidget);

    await tester.tap(heroPhoto);
    await tester.pumpAndSettle();

    // FullScreenImageViewer is pushed
    expect(find.byType(FullScreenImageViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Close viewer
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenImageViewer), findsNothing);
  });

  testWidgets('tapping document image opens FullScreenImageViewer', (
    WidgetTester tester,
  ) async {
    final state = AppState();

    final docPhoto = PropertyPhoto(
      id: 'photo_1',
      propertyId: 'test_doc_p',
      relativePath: 'media/properties/test_doc_p/photo.jpg',
      sortOrder: 0,
      createdAt: DateTime(2026, 8, 1),
    );
    final doc = PropertyDocument(
      id: 'doc_1',
      propertyId: 'test_doc_p',
      relativePath: 'media/properties/test_doc_p/doc.jpg',
      originalName: 'so_do.jpg',
      mimeType: 'image/jpeg',
      sortOrder: 0,
      createdAt: DateTime(2026, 8, 1),
    );

    final prop = Property(
      id: 'test_doc_p',
      title: 'Nhà có sổ đỏ',
      address: '123 Phố Huế',
      areaId: state.areas.first.id,
      status: PropertyStatus.selling,
      price: 10e9,
      landArea: 60,
      propertyType: state.propertyTypes.first,
      tags: const ['Góc'],
      createdAt: DateTime(2026, 8, 1),
      photos: [docPhoto],
      documents: [doc],
      mapX: 0.5,
      mapY: 0.5,
    );
    await state.addProperty(prop);

    await tester.pumpWidget(
      createDetailScreen(state: state, propertyId: 'test_doc_p'),
    );
    await tester.pumpAndSettle();

    // Scroll to documents section
    await tester.scrollUntilVisible(
      find.text('Tài liệu / Hình bổ sung'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Tài liệu / Hình bổ sung'), findsOneWidget);

    // Tap on the document photo view
    final docItem = find.byType(DocumentPhotoView).first;
    expect(docItem, findsOneWidget);
    await tester.tap(docItem);
    await tester.pumpAndSettle();

    // FullScreenImageViewer opens with the document
    expect(find.byType(FullScreenImageViewer), findsOneWidget);
    expect(find.text('so_do.jpg'), findsOneWidget);

    // Close viewer
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenImageViewer), findsNothing);
  });

  testWidgets('FullScreenImageViewer displays counter and navigates photos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FullScreenImageViewer.show(
                  context,
                  filePaths: const ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
                  seeds: const [1, 2, 3],
                  initialIndex: 1,
                  title: 'Xem ảnh BĐS',
                );
              },
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Viewer'));
    await tester.pumpAndSettle();

    expect(find.byType(FullScreenImageViewer), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Xem ảnh BĐS'), findsOneWidget);

    // Fling to next page
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
  });
}
