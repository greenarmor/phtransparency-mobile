import 'package:bettergov_budget/presentation/widgets/region_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _highlight(WidgetTester tester, String key) {
  final fade = tester.widget<AnimatedOpacity>(
    find.descendant(
      of: find.byKey(ValueKey('region-tab-$key')),
      matching: find.byType(AnimatedOpacity),
    ),
  );
  return fade.opacity;
}

Widget _app({required int index, required ValueChanged<int> onSelected}) =>
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: RegionTabBar(index: index, onSelected: onSelected),
      ),
    );

void main() {
  testWidgets('the highlight fills the whole tab, not just the icon', (
    tester,
  ) async {
    await tester.pumpWidget(_app(index: 0, onSelected: (_) {}));

    final cell = tester.getSize(find.byKey(const ValueKey('region-tab-money')));
    final highlight = tester.getSize(
      find.descendant(
        of: find.byKey(const ValueKey('region-tab-money')),
        matching: find.byType(AnimatedOpacity),
      ),
    );

    expect(highlight.width, cell.width);
    expect(highlight.height, cell.height);
  });

  testWidgets('the icon and label sit in the middle of the tab', (
    tester,
  ) async {
    await tester.pumpWidget(_app(index: 0, onSelected: (_) {}));

    final cell = tester.getRect(find.byKey(const ValueKey('region-tab-money')));
    final icon = tester.getCenter(find.byIcon(Icons.account_balance_wallet));
    final label = tester.getCenter(find.text('Money'));

    expect((icon.dx - cell.center.dx).abs(), lessThan(1));
    expect((label.dx - cell.center.dx).abs(), lessThan(1));
    expect(icon.dx, moreOrLessEquals(label.dx, epsilon: 1));
  });

  testWidgets('the whole tab is tappable, not just the label', (tester) async {
    var selected = -1;
    await tester.pumpWidget(_app(index: 0, onSelected: (i) => selected = i));

    final cell = tester.getRect(
      find.byKey(const ValueKey('region-tab-gaa')),
    );
    await tester.tapAt(Offset(cell.left + 12, cell.center.dy));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });

  testWidgets('the highlight follows the selected tab', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _app(
          index: selected,
          onSelected: (index) => setState(() => selected = index),
        ),
      ),
    );

    expect(_highlight(tester, 'money'), 1);
    expect(_highlight(tester, 'gaa'), 0);

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('region-tab-gaa'))),
    );
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(_highlight(tester, 'money'), 0);
    expect(_highlight(tester, 'gaa'), 1);
  });
}
