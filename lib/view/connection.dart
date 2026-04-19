import 'dart:convert';

import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'dart:convert';
import 'package:get/get.dart';

class PrinterController extends GetxController {
  final bluetooth = FlutterBluetoothClassic();

  var isBluetoothOn = false.obs;
  var bondedDevices = <BluetoothDevice>[].obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    initBluetooth();

    // 🔥 Listen connection state
    bluetooth.onConnectionChanged.listen((state) {
      isConnected.value = state.isConnected;
      if (!state.isConnected) {
        connectedDevice.value = null;
      }
    });
  }

  // 🔹 Init Bluetooth
  void initBluetooth() async {
    bool state = await bluetooth.isBluetoothEnabled();
    isBluetoothOn.value = state;
  }

  // 🔹 Turn ON
  Future<void> turnOn() async {
    await bluetooth.enableBluetooth();
    isBluetoothOn.value = true;
    getPairedDevices();
  }

  // 🔹 Turn OFF (Not supported directly)
  Future<void> turnOff() async {
    // ❗ No direct method in your library
    isBluetoothOn.value = false;
  }

  // 🔹 Get Paired Devices
  Future<void> getPairedDevices() async {
    try {
      List<BluetoothDevice> devices =
      await bluetooth.getPairedDevices();
      bondedDevices.value = devices;
    } catch (e) {
      print("Error fetching devices: $e");
    }
  }

  // 🔹 Connect
  Future<void> connect(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device.address);
      connectedDevice.value = device;
      isConnected.value = true;

      print("Connected to ${device.name}");
    } catch (e) {
      print("Connection error: $e");
    }
  }

  // 🔹 Disconnect
  Future<void> disconnect() async {
    await bluetooth.disconnect();
    isConnected.value = false;
    connectedDevice.value = null;
  }

  // 🔹 Print Text
  Future<void> printText(String text) async {
    if (!isConnected.value) return;

    await bluetooth.sendString(text + "\n");
  }

  // 🔹 Print Receipt
  Future<void> printReceipt() async {
    if (!isConnected.value) return;

    String data = '''
========================
     MY SHOP
------------------------
Item        Qty   Price
Apple       2     40
Milk        1     30
------------------------
Total:      70
========================
Thank You 🙏
''';

    await bluetooth.sendString(data);
  }
}

class PrinterScreen extends StatelessWidget {
  final controller = Get.put(PrinterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thermal Printer")),
      body: Column(
        children: [

          // 🔵 Bluetooth ON/OFF
          Obx(() => SwitchListTile(
            title: Text("Bluetooth"),
            value: controller.isBluetoothOn.value,
            onChanged: (val) {
              val ? controller.turnOn() : controller.turnOff();
            },
          )),

          // 🔍 Load Devices
          ElevatedButton(
            onPressed: controller.getPairedDevices,
            child: Text("Show Paired Devices"),
          ),

          // 📱 Device List
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.bondedDevices.length,
              itemBuilder: (context, index) {
                final device = controller.bondedDevices[index];

                return ListTile(
                  title: Text(device.name ?? "Unknown"),
                  subtitle: Text(device.address ?? ""),
                  trailing: ElevatedButton(
                    child: Text("Connect"),
                    onPressed: () => controller.connect(device),
                  ),
                );
              },
            )),
          ),

          // 🖨️ Print Button
          Obx(() => controller.isConnected.value
              ? Column(
            children: [
              ElevatedButton(
                onPressed: () => controller.printText("Hello Printer"),
                child: Text("Print Text"),
              ),
              ElevatedButton(
                onPressed: controller.printReceipt,
                child: Text("Print Receipt"),
              ),
              ElevatedButton(
                onPressed: controller.disconnect,
                child: Text("Disconnect"),
              ),
            ],
          )
              : SizedBox()),
        ],
      ),
    );
  }
}