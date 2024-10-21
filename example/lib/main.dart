import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

void main() => runApp(MyApp());

/// The main entry point of the application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Save Image to Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

/// A stateful widget that provides options to save local and network images or videos to the gallery.
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Key to capture a screenshot of the widget.
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save Image to Gallery"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            // Widget to capture and save as an image.
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.red,
              ),
            ),
            _buildButton("Save Local Image", _saveScreen),
            _buildButton("Save Network Image", _getHttp),
            _buildButton("Save Network Video", _saveVideo),
            _buildButton("Save Gif to Gallery", _saveGif),
          ],
        ),
      ),
    );
  }

  /// Builds a standardized button widget.
  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      padding: EdgeInsets.only(top: 15),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
      width: 200,
      height: 44,
    );
  }

  /// Requests necessary permissions based on the platform.
  Future<void> _requestPermission() async {
    bool statuses;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      statuses = sdkInt < 29 ? await Permission.storage.request().isGranted : true;
    } else {
      statuses = await Permission.photosAddOnly.request().isGranted;
    }
    _toastInfo('Permission Request Result: $statuses');
  }

  /// Captures the current screen and saves it as an image in the gallery.
  Future<void> _saveScreen() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        String picturesPath = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final result = await SaverGallery.saveImage(
          byteData.buffer.asUint8List(),
          fileName: picturesPath,
          skipIfExists: false,
        );
        _toastInfo(result.toString());
      }
    } catch (e) {
      _toastInfo('Error: $e');
    }
  }

  /// Downloads an image from the network and saves it to the gallery.
  Future<void> _getHttp() async {
    try {
      final response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes),
      );
      String picturesPath = "network_image.jpg";
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        fileName: picturesPath,
        androidRelativePath: "Pictures/NetworkImages",
        skipIfExists: true,
      );
      _toastInfo(result.toString());
    } catch (e) {
      _toastInfo('Error: $e');
    }
  }

  /// Downloads a GIF from the network and saves it to the gallery.
  Future<void> _saveGif() async {
    try {
      final response = await Dio().get(
        "https://test-1300597023.cos.ap-singapore.myqcloud.com/hyj-doc-flutter-demo-run%20%281%29.gif",
        options: Options(responseType: ResponseType.bytes),
      );
      String gifPath = "network_gif.gif";
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        fileName: gifPath,
        androidRelativePath: "Pictures/Gifs",
        skipIfExists: false,
      );
      _toastInfo(result.toString());
    } catch (e) {
      _toastInfo('Error: $e');
    }
  }

  /// Downloads a video from the network and saves it to the gallery.
  Future<void> _saveVideo() async {
    try {
      final dir = await getTemporaryDirectory();
      String savePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";
      String fileUrl = "https://test-1300597023.cos.ap-singapore.myqcloud.com/ForBiggerBlazes.mp4";

      await Dio().download(
        fileUrl,
        savePath,
        options: Options(
          sendTimeout: Duration(minutes: 10),
          receiveTimeout: Duration(minutes: 10),
        ),
        onReceiveProgress: (count, total) {
          debugPrint("${(count / total * 100).toStringAsFixed(0)}%");
        },
      );

      final result = await SaverGallery.saveFile(
        filePath: savePath,
        fileName: 'downloaded_video.mp4',
        androidRelativePath: "Movies",
        skipIfExists: true,
      );
      _toastInfo(result.toString());
    } catch (e) {
      _toastInfo('Error: $e');
    }
  }

  /// Displays a toast message with the given information.
  void _toastInfo(String info) {
    print(info);
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }
}
