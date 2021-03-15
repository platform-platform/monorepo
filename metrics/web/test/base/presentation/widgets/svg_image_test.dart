// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/platform/stub/renderer/renderer_stub.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/finder_util.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/renderer_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("SvgImage", () {
    const testImageSrc = 'src';
    final renderer = RendererMock();

    tearDown(() {
      reset(renderer);
    });

    testWidgets(
      "applies the default renderer if the given one is null",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _SvgImageTestbed(renderer: null));
        });

        final svgImage = FinderUtil.findSvgImage(tester);

        expect(svgImage.renderer, isNotNull);
      },
    );

    testWidgets(
      "uses the given renderer to detect whether the SKIA renderer is used",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer),
          );
        });

        verify(renderer.isSkia).called(once);
      },
    );

    testWidgets(
      "displays the svg picture widget if the application uses the SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer),
          );
        });

        expect(find.byType(SvgPicture), findsOneWidget);
      },
    );

    testWidgets(
      "applies the given src to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(src: testImageSrc, renderer: renderer),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);
        final picture = svgPicture.pictureProvider as NetworkPicture;

        expect(picture.url, equals(testImageSrc));
      },
    );

    testWidgets(
      "applies the given alignment to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        const alignment = Alignment.bottomLeft;
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(alignment: alignment, renderer: renderer),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.alignment, equals(alignment));
      },
    );

    testWidgets(
      "aligns the svg picture to the center if the given alignment is null when using SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(alignment: null, renderer: renderer),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.alignment, equals(Alignment.center));
      },
    );

    testWidgets(
      "applies the BoxFit.none to the svg picture widget if the given fit is null when using SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer, fit: null),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.fit, equals(BoxFit.none));
      },
    );

    testWidgets(
      "applies the given fit to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        const fit = BoxFit.contain;
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer, fit: fit),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.fit, equals(fit));
      },
    );

    testWidgets(
      "applies the given width to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        const width = 10.0;
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer, width: width),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.width, equals(width));
      },
    );

    testWidgets(
      "applies the given height to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        const height = 10.0;
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer, height: height),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.height, equals(height));
      },
    );

    testWidgets(
      "applies the given color to the svg picture widget when using SKIA renderer",
      (WidgetTester tester) async {
        const color = Colors.red;
        const expectedColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
        when(renderer.isSkia).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer, color: color),
          );
        });

        final svgPicture = FinderUtil.findSvgPicture(tester);

        expect(svgPicture.colorFilter, equals(expectedColorFilter));
      },
    );

    testWidgets(
      "displays the network image widget if the application doesn't use the SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(renderer: renderer),
          );
        });

        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      "applies the given src to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(
              src: testImageSrc,
              renderer: renderer,
            ),
          );
        });

        final image = FinderUtil.findImage(tester);
        final networkImage = image.image as NetworkImage;

        expect(networkImage.url, equals(testImageSrc));
      },
    );

    testWidgets(
      "aligns to the network image to the center if the given alignment is null when not using the SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(alignment: null, renderer: renderer),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.alignment, equals(Alignment.center));
      },
    );

    testWidgets(
      "applies the given alignment to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        const alignment = Alignment.bottomLeft;
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(
              alignment: alignment,
              renderer: renderer,
            ),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.alignment, equals(alignment));
      },
    );

    testWidgets(
      "applies the given fit to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        const fit = BoxFit.contain;
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(fit: fit, renderer: renderer),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.fit, equals(fit));
      },
    );

    testWidgets(
      "applies the BoxFit.none to the network image widget if the given fit is null when not using the SKIA renderer",
      (WidgetTester tester) async {
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(fit: null, renderer: renderer),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.fit, equals(BoxFit.none));
      },
    );

    testWidgets(
      "applies the given height to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        const height = 20.0;
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(height: height, renderer: renderer),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.height, equals(height));
      },
    );

    testWidgets(
      "applies the given width to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        const width = 20.0;
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(width: width, renderer: renderer),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.width, equals(width));
      },
    );

    testWidgets(
      "applies the given color to the network image widget when not using the SKIA renderer",
      (WidgetTester tester) async {
        const color = Colors.red;
        when(renderer.isSkia).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _SvgImageTestbed(
              renderer: renderer,
              color: color,
            ),
          );
        });

        final image = FinderUtil.findImage(tester);

        expect(image.color, equals(color));
      },
    );
  });
}

/// A testbed class needed to test the [SvgImage] widget.
class _SvgImageTestbed extends StatelessWidget {
  /// A default source of the [SvgImage].
  static const String _defaultSrc = 'default src';

  /// A source of the [SvgImage].
  final String src;

  /// A height of the [SvgImage].
  final double height;

  /// A width of the [SvgImage].
  final double width;

  /// A [BoxFit] of the [SvgImage].
  final BoxFit fit;

  /// A [Color] of the [SvgImage].
  final Color color;

  /// An [AlignmentGeometry] of the [SvgImage].
  final AlignmentGeometry alignment;

  /// A [Renderer] of the [SvgImage].
  final Renderer renderer;

  /// Creates a new instance of the svg image testbed.
  ///
  /// The [src] defaults to default src.
  const _SvgImageTestbed({
    this.src = _defaultSrc,
    this.fit,
    this.height,
    this.width,
    this.color,
    this.alignment,
    this.renderer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SvgImage(
          src,
          fit: fit,
          height: height,
          width: width,
          color: color,
          alignment: alignment,
          renderer: renderer,
        ),
      ),
    );
  }
}
