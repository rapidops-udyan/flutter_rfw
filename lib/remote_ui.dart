import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rfw/api.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

class RemoteUi extends StatefulWidget {
  const RemoteUi({super.key});

  @override
  State<RemoteUi> createState() => _RemoteUiState();
}

class _RemoteUiState extends State<RemoteUi> {
  late final Runtime _runtime;
  final DynamicContent _dynamicContent = DynamicContent();
  final CollectionReference _data =
      FirebaseFirestore.instance.collection('config');
  static const LibraryName _mainName = LibraryName(['main']);
  static const LibraryName _localName = LibraryName(['local']);
  static const FullyQualifiedWidgetName _widgetName =
      FullyQualifiedWidgetName(_mainName, 'root');
  RemoteWidgetLibrary? _remoteWidgetLibrary;
  final ValueNotifier<bool> _isReady = ValueNotifier(false);
  final _api = API();
  final ValueNotifier<String> _imageBase64 = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _runtime = Runtime();
    _initializeRuntime();
    _fetchData();
  }

  @override
  void dispose() {
    _runtime.dispose();
    _isReady.dispose();
    _imageBase64.dispose(); // Dispose _imageBase64
    super.dispose();
  }

  void _initializeRuntime() {
    _runtime
      ..update(_localName, _createLocalWidgets())
      ..update(const LibraryName(['core', 'widgets']), createCoreWidgets())
      ..update(
          const LibraryName(['core', 'material']), createMaterialWidgets());
  }

  void _updateData(String key, value) {
    _dynamicContent.update(key, value);
  }

  Future<void> _fetchData() async {
    try {
      final snapshot = await _data.doc('ui').get();
      final value = snapshot.get('root') as String?;
      if (value != null) {
        _remoteWidgetLibrary = parseLibraryFile(value);
        if (_remoteWidgetLibrary != null) {
          _runtime.update(_mainName, _remoteWidgetLibrary!);
          _isReady.value = true;
        }
      }
    } catch (e) {
      // TODO: Implement proper error handling
    }
  }

  WidgetLibrary _createLocalWidgets() {
    return LocalWidgetLibrary(
      {
        'CustomTextField': (BuildContext context, DataSource source) =>
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(source.v<double>(['radius']) ?? 0.0),
                  ),
                ),
                filled: source.v<bool>(['filled']) ?? false,
                fillColor: ArgumentDecoders.color(source, ['fillColor']),
                hintText: source.v<String>(['hintText']) ?? "",
                hintStyle: const TextStyle(color: Colors.white),
              ),
              onSubmitted: (String value) {
                _updateData('url', value.trim());
              },
            ),
        'CustomFAB': (BuildContext context, DataSource source) =>
            FloatingActionButton(
              onPressed: source.voidHandler(['find']),
              backgroundColor:
                  ArgumentDecoders.color(source, ['backgroundColor']),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
              ),
            ),
        'Logo': (BuildContext context, DataSource source) {
          final imageBase64 = source.v<String>(['image']) ?? '';
          _imageBase64.value = imageBase64;
          return Expanded(
            child: Container(
              margin: ArgumentDecoders.edgeInsets(source, ['margin']),
              child: ValueListenableBuilder<String>(
                valueListenable: _imageBase64,
                builder: (context, image, _) {
                  if (image.isNotEmpty) {
                    return Image.memory(base64Decode(image));
                  } else {
                    return const Image(
                      image: AssetImage('assets/default.png'),
                    );
                  }
                },
              ),
            ),
          );
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isReady,
      builder: (context, isReady, _) {
        return isReady
            ? RemoteWidget(
                runtime: _runtime,
                widget: _widgetName,
                data: _dynamicContent,
                onEvent: (String name, DynamicMap arguments) async {
                  if (name == 'find') {
                    final url = arguments['url'].toString();
                    print(url);
                    final data = await _api.fetchImage(url);
                    final base64Image = base64Encode(data);
                    _imageBase64.value = base64Image;
                    _updateData('image', base64Image);
                  }
                },
              )
            : const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
