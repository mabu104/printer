import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:image/image.dart' as im;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
//import 'package:ping_discover_network/ping_discover_network.dart';
//import 'package:wifi/wifi.dart';

extension PdfRasterExt on PdfRaster {
  im.Image asImage() {
    return im.Image.fromBytes(width, height, pixels);
  }
}

const printerIp = '192.168.0.123';
const printerDpi = 203.0;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  findPrinter() async {
    // const port = 80;
    // final stream = NetworkAnalyzer.discover2(
    //   '192.168.0',
    //   port,
    //   timeout: Duration(milliseconds: 5000),
    // );

    // int found = 0;
    // stream.listen((NetworkAddress addr) {
    //   if (addr.exists) {
    //     found++;
    //     print('Found device: ${addr.ip}:$port');
    //   }
    // }).onDone(() => print('Finish. Found $found device(s)'));
    // final String ip = await Wifi.ip;
    // final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    // final int port = 80;

    // final stream = NetworkAnalyzer.discover2(subnet, port);
    // stream.listen((NetworkAddress addr) {
    //   if (addr.exists) {
    //     print('Found device: ${addr.ip}');
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                findPrinter();
              },
            ),
          ],
        ),
        body: PdfPreview(
          build: (_) => _buildDocument(),
          allowPrinting: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowSharing: false,
          // actions: [
          //   PdfPreviewAction(
          //     icon: const Icon(Icons.print),
          //     onPressed: (context, build, pageFormat) => _print(),
          //   )
          // ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildDocument() async {
    final doc = pdf.Document();

    doc.addPage(
      pdf.Page(
        //orientation: pdf.PageOrientation.landscape,
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pdf.Column(
          children: [
            pdf.Text(
              'Hello World',
              style: pdf.TextStyle(
                fontWeight: pdf.FontWeight.bold,
                fontSize: 20,
              ),
            ),
            pdf.BarcodeWidget(
                data: 'mabu104',
                barcode: pdf.Barcode.qrCode(),
                width: 80,
                height: 80),
          ],
        ),
      ),
    );

    // doc.addPage(
    //   pdf.Page(
    //     pageFormat: PdfPageFormat.roll80,
    //     build: (context) => pdf.Center(
    //       child: pdf.PdfLogo(),
    //     ),
    //   ),
    // );

    return await doc.save();
  }

  Future<void> _print() async {
    final printer = PrinterNetworkManager(printerIp);
    final res = await printer.connect();

    if (res != PosPrintResult.success) {
      throw Exception('Unable to connect to the printer');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var ticket = <int>[];

    await for (var page
        in Printing.raster(await _buildDocument(), dpi: printerDpi)) {
      final image = page.asImage();
      ticket += generator.image(image);
      ticket += generator.feed(2);
      ticket += generator.cut();
    }

    printer.printTicket(ticket);
    printer.disconnect();
  }
}
