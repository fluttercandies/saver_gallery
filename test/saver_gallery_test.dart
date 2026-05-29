import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saver_gallery/saver_gallery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel("com.fluttercandies/saver_gallery");

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, dynamic>{"isSuccess": true, "errorMessage": null};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test("SaveResult parses savedUri and mirrors it into savedUris", () {
    final result = SaveResult.fromMap(<String, dynamic>{
      "isSuccess": true,
      "errorMessage": null,
      "savedUri": "content://media/external/images/media/1",
    });

    expect(result.isSuccess, true);
    expect(result.errorMessage, null);
    expect(result.savedUri, "content://media/external/images/media/1");
    expect(result.savedUris, <String>["content://media/external/images/media/1"]);
  });

  test("SaveResult parses savedUris", () {
    final result = SaveResult.fromMap(<String, dynamic>{
      "isSuccess": true,
      "errorMessage": null,
      "savedUris": <String>["content://one", "content://two"],
    });

    expect(result.isSuccess, true);
    expect(result.errorMessage, null);
    expect(result.savedUri, null);
    expect(result.savedUris, <String>["content://one", "content://two"]);
  });

  test("SaveResult uses empty uri fields when save failed", () {
    final result = SaveResult.fromMap(<String, dynamic>{
      "isSuccess": false,
      "errorMessage": "failed",
    });

    expect(result.isSuccess, false);
    expect(result.errorMessage, "failed");
    expect(result.savedUri, null);
    expect(result.savedUris, isEmpty);
  });

  test("saveImage exposes native savedUri", () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, dynamic>{
        "isSuccess": true,
        "errorMessage": null,
        "savedUri": "content://media/external/images/media/1",
      };
    });

    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      skipIfExists: false,
    );

    expect(result.isSuccess, true);
    expect(result.savedUri, "content://media/external/images/media/1");
    expect(result.savedUris, <String>["content://media/external/images/media/1"]);
  });

  test("saveFiles exposes native savedUris", () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, dynamic>{
        "isSuccess": true,
        "errorMessage": null,
        "savedUris": <String>["content://one", "content://two"],
      };
    });

    final result = await SaverGallery.saveFiles(<SaveFileData>[
      SaveFileData(filePath: "/tmp/sample.png", fileName: "sample.png"),
      SaveFileData(filePath: "/tmp/sample.mp4", fileName: "sample.mp4"),
    ], skipIfExists: false);

    expect(result.isSuccess, true);
    expect(result.savedUri, null);
    expect(result.savedUris, <String>["content://one", "content://two"]);
  });

  test("saveImage maps albumPath to Pictures relativePath", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "MyAlbum",
      skipIfExists: false,
    );

    expect(result.isSuccess, true);
    expect(calls, hasLength(1));
    expect(calls.single.method, "saveImageToGallery");

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments["relativePath"], "Pictures/MyAlbum");
    expect(arguments["albumPath"], "MyAlbum");
  });

  test("saveImage combines neutral albumPath with default image directory", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "appName/images",
      skipIfExists: false,
    );

    expect(result.isSuccess, true);
    expect(calls, hasLength(1));

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments["relativePath"], "Pictures/appName/images");
    expect(arguments["albumPath"], "appName/images");
  });

  test("saveImage keeps albumPath with known public directory prefix", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "Pictures/appName/images",
      skipIfExists: false,
    );

    expect(result.isSuccess, true);
    expect(calls, hasLength(1));

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments["relativePath"], "Pictures/appName/images");
    expect(arguments["albumPath"], "Pictures/appName/images");
  });

  test("saveFile maps video albumPath to Movies relativePath", () async {
    final result = await SaverGallery.saveFile(
      filePath: "/tmp/sample.mp4",
      fileName: "sample.mp4",
      albumPath: "appName/videos",
      skipIfExists: false,
    );

    expect(result.isSuccess, true);
    expect(calls, hasLength(1));

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments["relativePath"], "Movies/appName/videos");
    expect(arguments["albumPath"], "appName/videos");
  });

  test("saveFiles preserves per-file albumPath and relativePath", () async {
    final result = await SaverGallery.saveFiles(<SaveFileData>[
      SaveFileData(
        filePath: "/tmp/sample.png",
        fileName: "sample.png",
        albumPath: "appName/images",
      ),
      SaveFileData(
        filePath: "/tmp/sample.mp4",
        fileName: "sample.mp4",
        albumPath: "appName/videos",
      ),
    ], skipIfExists: false);

    expect(result.isSuccess, true);
    expect(calls, hasLength(1));

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    final files = arguments["files"] as List<Object?>;

    expect(files[0], containsPair("relativePath", "Pictures/appName/images"));
    expect(files[0], containsPair("albumPath", "appName/images"));
    expect(files[1], containsPair("relativePath", "Movies/appName/videos"));
    expect(files[1], containsPair("albumPath", "appName/videos"));
  });

  test("invalid albumPath returns failure without calling native channel", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "bad/../name",
      skipIfExists: false,
    );

    expect(result.isSuccess, false);
    expect(result.errorMessage, contains("albumPath"));
    expect(calls, isEmpty);
  });

  test("absolute albumPath returns failure without calling native channel", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "/Pictures",
      skipIfExists: false,
    );

    expect(result.isSuccess, false);
    expect(result.errorMessage, contains("albumPath"));
    expect(calls, isEmpty);
  });

  test("windows absolute albumPath returns failure without calling native channel", () async {
    final result = await SaverGallery.saveImage(
      Uint8List.fromList(<int>[1, 2, 3]),
      extension: "png",
      fileName: "sample.png",
      albumPath: "C:/Pictures",
      skipIfExists: false,
    );

    expect(result.isSuccess, false);
    expect(result.errorMessage, contains("albumPath"));
    expect(calls, isEmpty);
  });
}
