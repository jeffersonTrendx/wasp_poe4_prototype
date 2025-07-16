import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WaspBleScreen(),
    );
  }
}

class WaspBleScreen extends StatefulWidget {
  const WaspBleScreen({super.key});

  @override
  State<WaspBleScreen> createState() => _WaspBleScreenState();
}

class _WaspBleScreenState extends State<WaspBleScreen> {
  final List<MyBeatDeviceBroadcast> devices = [];
  late RawDatagramSocket socket;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  Future<void> initSocket() async {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 51113,
        reuseAddress: true);
    listenToMulticastPackets((device) {
      setState(() {
        // if (device.id == 22) {
        devices.add(device);
        if (devices.length > 20) devices.removeAt(0);
        // }
      });
    });
  }

  Future<void> listenToMulticastPackets(
      Function(MyBeatDeviceBroadcast) onDeviceFound) async {
    socket.joinMulticast(InternetAddress("239.78.80.1"));
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final data = datagram.data;
          if (data.length >= 2) {
            if (data[0] == 0x42 && data[1] == 0x4C) {
              _handleWasPBlePacket(data, onDeviceFound);
            }
          }
        }
      }
    });
  }

  void _handleWasPBlePacket(
      Uint8List packet, Function(MyBeatDeviceBroadcast) onDeviceFound) {
    int index = 5; // pula "42 4C XX XX LL"
    while (index < packet.length) {
      if (packet[index] == 0x4E) {
        final subPacketLength = packet[index - 1];
        if (index + 1 + subPacketLength <= packet.length) {
          final subPacket =
              packet.sublist(index + 1, index + 1 + subPacketLength);
          final parsed = parseSubPacket(subPacket);
          if (parsed != null) {
            onDeviceFound(parsed);
          }
          index += 1 + subPacketLength;
        } else {
          break;
        }
      } else {
        index++;
      }
    }
  }

  MyBeatDeviceBroadcast? parseSubPacket(Uint8List data) {
    if (data.length < 12) return null;

    // MAC do byte 3 ao 8 , invertido (little endian → big endian)
    final macBytes =
        data.length >= 9 ? data.sublist(3, 9).reversed.toList() : [];
    final mac =
        macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

    final rssi = data[9] > 127 ? data[9] - 256 : data[9];
    const advStart = 9;
    final advertisingData = data.sublist(advStart);

    String? name;
    Uint8List? manufacturerRaw;
    int i = 0;
    while (i < advertisingData.length) {
      if (i + 1 >= advertisingData.length) break;

      final length = advertisingData[i];
      if (length == 0 || i + 1 + length > advertisingData.length) {
        i++;
        continue;
      }

      final type = advertisingData[i + 1];
      final value = advertisingData.sublist(i + 2, i + 1 + length);

      if (type == 0x09 && value.isNotEmpty) {
        name = String.fromCharCodes(value);
      }

      if (type == 0xFF && value.length >= 2) {
        manufacturerRaw =
            Uint8List.fromList([value[1], value[0], ...value.sublist(2)]);
      }

      i += length + 1;
    }

    if (manufacturerRaw == null || manufacturerRaw.length < 6) return null;

    try {
      final device = DiscoveredDevice(
        id: mac,
        name: name ?? '',
        serviceData: {},
        manufacturerData: manufacturerRaw,
        rssi: rssi,
        serviceUuids: [],
      );
      if (manufacturerRaw[2] == 22) {
        debugPrint(device.toString());
      }
      return myBeatDeviceBroadcastsSerializer.from(device);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyBeat BLE Devices')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      devices.clear();
                      initSocket();
                    });
                  },
                  child: const Text('conectar')),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      devices.clear();
                      socket.close();
                    });
                  },
                  child: const Text('desconectar')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text("ID: ${d.id}  •  HR: ${d.heartRate}"),
                    subtitle:
                        Text("Room: ${d.roomNumber}   •   Name : ${d.name}"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
