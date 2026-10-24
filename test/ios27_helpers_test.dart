import 'package:bluebubbles/helpers/ui/ios27_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders iOS 27 glass chrome in light and dark themes', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Ios27Background(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ios27Glass(child: const Text('glass')),
                  Ios27GlassButton(
                    onTap: () {},
                    child: const Icon(Icons.search),
                  ),
                  Ios27GlassPill(child: const Text('pill')),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('glass'), findsOneWidget);
      expect(find.text('pill'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    }
  });
}
