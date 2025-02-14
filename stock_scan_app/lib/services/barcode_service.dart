import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class BarcodeService {
  Future<String> scanBarcode() async {
    try {
      return await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.DEFAULT);
    } catch (e) {
      return 'Error scanning';
    }
  }
}
