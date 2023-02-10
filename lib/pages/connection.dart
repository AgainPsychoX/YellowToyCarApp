import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/drawer.dart';
import 'package:yellow_toy_car/utils/address.dart';
import 'package:yellow_toy_car/utils/padding.dart';

class _ConnectForm extends StatefulWidget {
  const _ConnectForm({Key? key}) : super(key: key);

  @override
  State<_ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends State<_ConnectForm> {
  late TextEditingController _controller;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    SharedPreferences.getInstance().then((preferences) {
      if (_controller.text.isNotEmpty) return;
      final last = preferences.getString('last_address');
      if (last == null) return;
      _controller.text = last;
      // TODO: optionally auto-connect
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _connect() {
    setState(() => _isConnecting = true);
    Provider.of<CarController>(context, listen: false)
        .connect(_controller.text)
        .onError((error, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        action: SnackBarAction(label: 'Retry', onPressed: _connect),
        content: const Text('Failed to connect'),
      ));
    }).whenComplete(() {
      SharedPreferences.getInstance().then((p) {
        p.setString('last_address', _controller.text);
      });
      setState(() => _isConnecting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            enabled: !_isConnecting,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'IP or local name',
              isDense: true,
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _connect(),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connect,
              icon: _isConnecting
                  ? const SizedBox(
                      height: 24, width: 24, child: CircularProgressIndicator())
                  : const Icon(Icons.settings_remote_rounded),
              label: _isConnecting
                  ? const Text('Connecting...')
                  : const Text('Connect'),
            ),
          ),
        ]
            .map((widget) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: widget))
            .toList(),
      ),
    );
  }
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage>
    with WidgetsBindingObserver {
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setState(() {/* Update, for WiFi could been changed meanwhile */});
        break;
      default:
        break;
    }
  }

  Widget _buildFastControlsButtons(
      BuildContext context, CarController controller) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/controls/basic'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.videogame_asset_rounded, size: 40),
                      Text('Basic controls'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/controls/analog'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sports_esports_rounded, size: 40),
                      Text('Analog controls'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/controls/sensors'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.screen_rotation_rounded, size: 32),
                      ),
                      Text('Sensors controls'),
                    ],
                  ),
                ),
              ].insertBetweenAll(const SizedBox(width: 8)),
            ),
          ),
        ],
      ),
    );
  }

  String _addressSubtitleForConnection(CarConnection connection) {
    if (connection.address.isHostNumeric)
      return 'IP: ${connection.address.address}';
    return 'IP: ${connection.address.address}\nHostname: ${connection.address.host}';
  }

  List<Widget> _buildTilesControllerConnected(
      BuildContext context, CarController controller) {
    final connection = controller.connection!;
    return [
      ListTile(
        leading: const Icon(Icons.lan_rounded),
        title: const Text('Address'),
        subtitle: Text(_addressSubtitleForConnection(connection)),
        // TODO: onTap: navigate to networking settings page
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: connection.address.address));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Address copied to the clipboard'),
          ));
        },
      ),
      ListTile(
        leading: const Icon(Icons.sync_alt_rounded),
        title: const Text('Ping'),
        subtitle: const Text('Response time for HTTP requests'),
        trailing: Text('${connection.lastPing}ms'), // TODO: colors
        // TODO: onTap: single status request for single ping measurement, display toast
        // TODO: onLongPress: average for few periods, maybe graph history of ping in time
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => controller.disconnect(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Disconnect'),
          ),
        ),
      ),
    ];
  }

  Widget _buildWiFiNotConnected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 40),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Not connected to any WiFi network.'),
          ),
          ElevatedButton(
            onPressed: () => AppSettings.openWIFISettings(),
            child: const Text('Open WiFi settings'),
          )
        ],
      ),
    );
  }

  Widget _buildWiFiConnected(BuildContext context, String wifiName) {
    return Consumer<CarController>(
      builder: (context, controller, child) => ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_rounded),
            title: controller.isConnected
                ? const Text('Connected to the car!')
                : const Text('Not connected'),
            trailing: controller.isConnected
                ? const Icon(Icons.link_rounded, color: Colors.green)
                : const Icon(Icons.link_off_rounded, color: Colors.red),
            // TODO: onTap: try connecting and if failed: scroll to/focus the IP input
          ),
          if (controller.isConnected) const Divider(),
          if (controller.isConnected)
            _buildFastControlsButtons(context, controller),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.wifi_rounded),
            title: const Text('WiFi connection'),
            subtitle: Text('SSID: $wifiName'),
            onTap: () {
              // TODO: select between HotSpot & WiFi?
              AppSettings.openWIFISettings();
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: wifiName));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('WiFi name copied to the clipboard'),
              ));
            },
          ),
          // TODO: rebuild every 1s, use https://pub.dev/packages/timer_builder
          // TODO: implement RSSI for network_info_plus package
          // FutureBuilder(
          //   future: _networkInfo.getWifiRSSI(),
          //   builder: (context, snapshot) {
          //     if (snapshot.hasError) return Container(/* Nothing */);
          //     if (!snapshot.hasData) return const CircularProgressIndicator();
          //     final int rssi = snapshot.data!;
          //     return ListTile(
          //       // TODO: bars as icon?
          //       leading: rssi >= -50
          //           ? const Icon(Icons.wifi)
          //           : rssi >= -75
          //               ? const Icon(Icons.wifi_2_bar)
          //               : const Icon(Icons.wifi_1_bar),
          //       title: const Text('Signal strength'),
          //       subtitle: Text('RSSI: $rssi'),
          //       // TODO: text representation of RSSI instead numbers
          //       // TODO: colors
          //     );
          //   },
          // ),
          const Divider(),
          if (controller.isConnected)
            ..._buildTilesControllerConnected(context, controller)
          else
            const _ConnectForm()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text('Connection'),
      ),
      body: FutureBuilder(
        future: _networkInfo.getWifiName(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }
          final name = snapshot.data;
          return name != null && name.isNotEmpty
              ? _buildWiFiConnected(context, name)
              : _buildWiFiNotConnected(context);
          // TODO: Fix bug: `getWifiName` returns last connected name if disconnected.
          // if (!snapshot.hasData) {
          //   return const Center(child: CircularProgressIndicator());
          // }
          // final name = snapshot.data!;
          // return name.isNotEmpty
          //     ? _buildWiFiConnected(context, name)
          //     : _buildWiFiNotConnected(context);
        },
      ),
    );
  }
}
