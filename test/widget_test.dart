import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youju_ai/main.dart';
import 'package:youju_ai/ui.dart';

Future<void> mountApp(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const YoujuApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('theme switch changes the rendered theme and preserves navigation', (tester) async {
    await mountApp(tester);
    expect(Theme.of(tester.element(find.byType(AppShell))).brightness, Brightness.light);
    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppShell))).brightness, Brightness.dark);
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppShell))).brightness, Brightness.light);
  });

  testWidgets('search has an empty state and clearing restores results', (tester) async {
    await mountApp(tester);
    await tester.enterText(find.byKey(const Key('property-search')), 'no-such-address');
    await tester.pumpAndSettle();
    expect(find.text('暂时没有匹配的房源'), findsOneWidget);
    expect(find.byType(PropertyCard), findsNothing);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyCard), findsWidgets);
    expect(find.text('暂时没有匹配的房源'), findsNothing);
  });

  testWidgets('favorite follows the property into saved and detail and can be removed', (tester) async {
    await mountApp(tester);
    final firstCard = find.byType(PropertyCard).first;
    await tester.ensureVisible(firstCard);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: firstCard, matching: find.byType(FavoriteButton)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyRow), findsOneWidget);
    expect(find.text('25 Chicago Lane'), findsOneWidget);
    await tester.tap(find.byType(PropertyRow));
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPage), findsOneWidget);
    expect(find.text('已收藏 · 点击取消'), findsOneWidget);
    await tester.tap(find.text('已收藏 · 点击取消'));
    await tester.pumpAndSettle();
    expect(find.text('收藏这套房源'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('把心动的家留在这里'), findsOneWidget);
    expect(find.byType(PropertyRow), findsNothing);
  });

  testWidgets('filter application changes the map and home catalog consistently', (tester) async {
    await mountApp(tester);
    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '出租'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('apply-filters')));
    await tester.tap(find.byKey(const Key('apply-filters')));
    await tester.pumpAndSettle();
    expect(find.text('2 套演示房源'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('2 套演示房源 · 多伦多及周边'), findsOneWidget);
    expect(find.text('示意地图 · 非实际地理定位'), findsOneWidget);
  });

  testWidgets('all five tabs are navigable without overflow on a small phone', (tester) async {
    await mountApp(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    for (var i = 1; i < 5; i++) {
      await tester.tap(find.byKey(Key('nav-$i')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab $i should fit a 320px phone');
    }
    expect(find.text('欢迎来到悠居'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('尚未连接 AI 服务'), findsOneWidget);
  });
}
