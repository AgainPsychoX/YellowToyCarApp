import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:app_settings/app_settings.dart';
import 'package:yellow_toy_car/api.dart';
import 'package:yellow_toy_car/common/drawer.dart';

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
    // TODO: remember last good address (across app restarts)
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
    }).whenComplete(() => setState(() => _isConnecting = false));
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

RegExp parseIPv4RegExp = RegExp(r"^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$");

class _HomePageState extends State<HomePage> {
  // TODO: separate out the status tree, just like connect form?
  List<Widget> _buildStatusTiles(
      BuildContext context, CarController controller) {
    final connection = controller.connection!;
    return [
      ListTile(
        leading: const Icon(Icons.lan_rounded),
        title: const Text('Address'),
        subtitle: Text(parseIPv4RegExp.hasMatch(connection.address)
            ? 'IP: ${connection.address}'
            : 'Hostname: ${connection.address}'),
        // TODO: onTap: navigate to networking settings page
        // TODO: onLongPress: copy to clipboard?
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
        padding: const EdgeInsets.all(8.0),
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
      child: Column(children: [
        const Icon(Icons.wifi),
        const Text('You are not connected to any WiFi network.'),
        ElevatedButton(
            onPressed: () {
              AppSettings.openWIFISettings();
              // .then((value) => setState(() {}));
            },
            child: const Text('Open WiFi settings'))
      ]),
    );
  }

  Widget _buildWiFiConnected(BuildContext context) {
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.wifi_rounded),
            title: const Text('WiFi connection'),
            subtitle: FutureBuilder(
                future: WiFiForIoTPlugin.getSSID().then((value) =>
                    (value != null && value.isNotEmpty)
                        ? value
                        : '(not connected)'),
                builder: (context, snapshot) => snapshot.hasError
                    ? const Text('Error getting SSID')
                    : snapshot.hasData
                        ? Text('Connected to SSID: ${snapshot.data!}')
                        : const Text('Loading...')),
            onTap: () {
              // TODO: select between HotSpot & WiFi?
              AppSettings.openWIFISettings();
              // .then((value) => setState(() {}));
            },
            // TODO: onLongPress: copy to clipboard?
          ),
          // TODO: rebuild every 1s, use https://pub.dev/packages/timer_builder
          FutureBuilder(
            future: WiFiForIoTPlugin.getCurrentSignalStrength(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Container(/* Nothing */);
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final int rssi = snapshot.data!;
              return ListTile(
                // TODO: bars as icon?
                leading: rssi >= -50
                    ? const Icon(Icons.wifi)
                    : rssi >= -75
                        ? const Icon(Icons.wifi_2_bar)
                        : const Icon(Icons.wifi_1_bar),
                title: const Text('Signal strength'),
                subtitle: Text('RSSI: $rssi'),
                // TODO: text representation of RSSI instead numbers
                // TODO: colors
              );
            },
          ),
          const Divider(),
          if (controller.isConnected)
            ..._buildStatusTiles(context, controller)
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
        title: const Text('Home page'),
      ),
      body: FutureBuilder(
        future: WiFiForIoTPlugin.isConnected(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final isWiFiConnected = snapshot.data!;
          return isWiFiConnected
              ? _buildWiFiConnected(context)
              : _buildWiFiNotConnected(context);
        },
      ),
    );
  }
}
