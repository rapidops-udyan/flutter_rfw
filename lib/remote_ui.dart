import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final LibraryName mainName = const LibraryName(<String>['main']);
  final LibraryName localName = const LibraryName(<String>['local']);
  RemoteWidgetLibrary? _remoteWidgetLibrary;
  bool _isReady = false;

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
    super.dispose();
  }

  void _initializeRuntime() {
    _runtime.update(localName, _createLocalWidgets());
    _runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['core', 'material']),
      createMaterialWidgets(),
    );
  }

  Future<void> _fetchData() async {
    try {
      final snapshot = await _data.doc('ui').get();
      if (snapshot.exists) {
        final value = snapshot.get('root');
        if (value != null && value is String) {
          _remoteWidgetLibrary = parseLibraryFile(value);
          if (_remoteWidgetLibrary != null) {
            _runtime.update(mainName, _remoteWidgetLibrary!);
            setState(() {
              _isReady = true;
            });
          }
        }
      }
    } catch (e) {
      // Handle errors appropriately in a real application
    }
  }

  static WidgetLibrary _createLocalWidgets() {
    return LocalWidgetLibrary(
      <String, LocalWidgetBuilder>{
        'CustomIcon': (BuildContext context, DataSource source) {
          return const Icon(Icons.flutter_dash_rounded);
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return !_isReady
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : RemoteWidget(
            runtime: _runtime,
            widget:
                const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
            data: _dynamicContent,
            onEvent: (eventName, eventArguments) {
              if (eventName == 'showSnackBar') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Remote Flutter Widgets'),
                  ),
                );
              }
            },
          );
  }
}
