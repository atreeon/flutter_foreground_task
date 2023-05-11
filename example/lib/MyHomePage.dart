import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task_example/taskHandler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReceivePort? _receivePort;

  Future<bool> _startForegroundTask() async {
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted = await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        print('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }

    FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
    );

    var receivePort = FlutterForegroundTask.receivePort;

    print('register receivePort start');

    var isRegistered = _registerReceivePort(receivePort);

    print('register receivePort done: $isRegistered');

    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    return true;
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen(
      (message) {
        print('receivePort: $message');
      },
      onError: (error) => print('receivePort error: $error'),
      onDone: () => print('on done'),
    );

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 2000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  CameraDescription? _camera;

  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();

    availableCameras().then(
      (value) {
        setState(
          () {
            _camera = value.first;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _closeReceivePort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              _startForegroundTask();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                //todo: fix this
                // Future.delayed(Duration(seconds: 5), () async {
                //   if (await FlutterForegroundTask.isRunningService) {
                //     final newReceivePort = FlutterForegroundTask.receivePort;
                //     _registerReceivePort(newReceivePort);
                //     print("Service is running!");
                //   } else {
                //     print('Service is not running!');
                //   }
                // });
              });
            },
            child: Text("Start service")),
        ElevatedButton(
            onPressed: () {
              FlutterForegroundTask.stopService();
            },
            child: Text("Stop service")),
      ],
    );
  }
}

class ResumeRoutePage extends StatelessWidget {
  const ResumeRoutePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resume Route'),
          centerTitle: true,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Go back!'),
          ),
        ),
      ),
    );
  }
}
