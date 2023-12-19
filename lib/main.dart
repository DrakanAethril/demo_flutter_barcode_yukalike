import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  String manualISBN = '';
  String productName = '';
  String brand = '';
  String imageURL = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISBN Book Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 300,
              width: 300,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (controller) {
                  this.controller = controller;
                  controller.scannedDataStream.listen((scanData) async {
                    // Handle scanned data if needed
                    if (scanData.code != null) {
                      await getProductInfo(scanData.code.toString());
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('OR'),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                manualISBN = value;
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (manualISBN.isNotEmpty) {
                  await getProductInfo(manualISBN);
                }
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 20),
            Text('Title: $productName'),
            Text('Author: $brand'),
            const SizedBox(height: 20),
            imageURL.isNotEmpty
                ? Image.network(
                    imageURL,
                    height: 200,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> getProductInfo(String isbn) async {
    final response = await http.get(
      Uri.parse('https://world.openfoodfacts.org/api/v2/product/$isbn.json'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      inspect(data);
      if (data.containsKey('product')) {
        var productInfo = data['product'];
        setState(() {
          productName = productInfo['product_name_fr'];
          brand = productInfo['brands'] != null
              ? productInfo['brands']
              : '';
          //imageURL = bookInfo['imageLinks']['thumbnail'] ?? '';
        });
      } else {
        setState(() {
          productName = 'Product not found';
          brand = '';
          imageURL = '';
        });
      }
    } else {
      setState(() {
        productName = 'Error fetching product information';
        brand = '';
        imageURL = '';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
