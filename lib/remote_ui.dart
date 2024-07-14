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
      FirebaseFirestore.instance.collection('counter_app');
  final LibraryName mainName = const LibraryName(<String>['main']);
  RemoteWidgetLibrary? _remoteWidgetLibrary; // Remove 'late' keyword here
  int _counter = 0;

  @override
  void initState() {
    _runtime = Runtime();
    _runtime.update(
        const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
    _runtime.update(const LibraryName(<String>['core', 'material']),
        createMaterialWidgets());
    _fetchData();
    super.initState();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _data.get().then((QuerySnapshot snapshot) {
      final value = snapshot.docs.first.get('main');
      setState(() {
        _remoteWidgetLibrary = parseLibraryFile(value.toString());
      });
      if (_remoteWidgetLibrary != null) {
        _runtime.update(mainName, _remoteWidgetLibrary!);
        _dynamicContent.update('counter', _counter.toString());
      }
    });
  }

  void _updateData() {
    _dynamicContent.update('counter', _counter.toString());
  }

  @override
  Widget build(BuildContext context) {
    return _remoteWidgetLibrary == null
        ? const Center(child: CircularProgressIndicator())
        : RemoteWidget(
            runtime: _runtime,
            widget: const FullyQualifiedWidgetName(
                LibraryName(['main']), 'Counter'),
            data: _dynamicContent,
            onEvent: (eventName, eventArguments) {
              if (eventName == 'increment') {
                setState(() {
                  _counter++;
                  _updateData();
                });
              }
            },
          );
  }
}
