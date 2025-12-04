// // Add these dependencies to pubspec.yaml:
// // dependencies:
// //   file_picker: ^8.0.0
// //   archive: ^3.4.0
// //   excel: ^4.0.0
// //   path_provider: ^2.1.0

// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:archive/archive.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';


// class BulkProductUploadScreen extends StatefulWidget {
//   @override
//   _BulkProductUploadScreenState createState() => _BulkProductUploadScreenState();
// }

// class _BulkProductUploadScreenState extends State<BulkProductUploadScreen> {
//   bool isProcessing = false;
//   String statusMessage = '';
//   List<ProductData> processedProducts = [];
//   int uploadedCount = 0;

// Future<void> pickAndProcessZipOrCsvXlsxFile() async {
//   try {
//     setState(() {
//       isProcessing = true;
//       statusMessage = 'Selecting file...';
//     });

//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['zip', 'csv', 'xlsx', 'xls'],
//     );

//     if (result == null) {
//       setState(() {
//         isProcessing = false;
//         statusMessage = 'No file selected';
//       });
//       return;
//     }

//     final file = File(result.files.single.path!);
//     final ext = file.path.split('.').last.toLowerCase();

//     // 📌 Direct CSV/XLSX without ZIP
//     if (ext == 'csv') {
//       setState(() => statusMessage = 'Processing CSV file...');
//       final products = await _processCsvFile(file);
//       setState(() {
//         processedProducts = products;
//         isProcessing = false;
//         statusMessage = '✅ Successfully read ${products.length} products from CSV!';
//       });
//       _showSuccessDialog(products);
//       return;
//     }

//     if (ext == 'xlsx' || ext == 'xls') {
//       setState(() => statusMessage = 'Processing Excel file...');
//       final products = await _processExcelOnly(file);
//       setState(() {
//         processedProducts = products;
//         isProcessing = false;
//         statusMessage = '✅ Successfully read ${products.length} products from Excel!';
//       });
//       _showSuccessDialog(products);
//       return;
//     }

//     // 📌 If ZIP
//     if (ext == 'zip') {
//       setState(() => statusMessage = 'Extracting ZIP file...');
//       final bytes = await file.readAsBytes();
//       final archive = ZipDecoder().decodeBytes(bytes);

//       final tempDir = await getTemporaryDirectory();
//       final extractPath = '${tempDir.path}/bulk_${DateTime.now().millisecondsSinceEpoch}';
//       Directory(extractPath).createSync(recursive: true);

//       Map<String, File> extractedImages = {};
//       File? csvFile;
//       File? excelFile;

//       for (final f in archive) {
//         if (f.isFile) {
//           final data = f.content as List<int>;
//           final outFile = File('$extractPath/${f.name}')..createSync(recursive: true)
//             ..writeAsBytesSync(data);

//           if (f.name.toLowerCase().endsWith('.csv')) {
//             csvFile = outFile;
//           }
//           if (f.name.toLowerCase().endsWith('.xlsx') || f.name.toLowerCase().endsWith('.xls')) {
//             excelFile = outFile;
//           }
//           if (f.name.contains('images/') &&
//               (f.name.endsWith('.jpg') || f.name.endsWith('.jpeg') || f.name.endsWith('.png'))) {
//             final imgName = f.name.split('/').last;
//             extractedImages[imgName] = outFile;
//           }
//         }
//       }

//       if (csvFile == null && excelFile == null) {
//         throw Exception('❌ No CSV or Excel file found inside ZIP!');
//       }

//       List<ProductData> products = [];
//       if (csvFile != null) {
//         setState(() => statusMessage = 'Processing CSV in ZIP...');
//         products = await _processCsvFile(csvFile, imageMap: extractedImages);
//       } else if (excelFile != null) {
//         setState(() => statusMessage = 'Processing Excel in ZIP...');
//         products = await _processExcelFile(excelFile, extractedImages);
//       }

//       setState(() {
//         processedProducts = products;
//         isProcessing = false;
//         statusMessage = '✅ Successfully processed ${products.length} ZIP products!';
//       });
//       _showSuccessDialog(products);
//     }

//   } catch (e) {
//     setState(() {
//       isProcessing = false;
//       statusMessage = 'Error: ${e.toString()}';
//     });

// log(e.toString());
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//     );


//   }
// }
// Future<List<ProductData>> _processCsvFile(File csvFile, {Map<String, File>? imageMap}) async {
//   final images = imageMap ?? {};
//   List<ProductData> products = [];

//   final bytes = await csvFile.readAsBytes();
  
//   // ✅ Try UTF-8, if fails use Latin1 (Excel sometimes saves CSV this way)
//   List<String> lines;
//   try {
//     lines = utf8.decode(bytes).split('\n');
//   } catch (_) {
//     log("⚠ UTF-8 failed, trying Latin1 decode...");
//     lines = latin1.decode(bytes).split('\n');
//   }

//   for (int i = 1; i < lines.length; i++) {
//     final row = lines[i].split(',');
//     if (row.length < 9) continue;

//     products.add(ProductData(
//       itemCode: row[0],
//       market: row[1],
//       name: row[2],
//       price: double.tryParse(row[3]) ?? 0,
//       offerPrice: row[4].isNotEmpty ? double.tryParse(row[4]) : null,
//       unit: row[5],
//       stock: int.tryParse(row[6]) ?? 0,
//       description: row[7],
//       categoryId: row[8],
//       imageFiles: (row.length > 15)
//           ? row[15].split(',').map((img) => images[img.trim()]).whereType<File>().toList()
//           : [],
//       isHidden: row.length > 14 && row[14].toLowerCase() == 'true',
//     ));
//   }

//   return products;
// }
// Future<List<ProductData>> _processExcelOnly(File excelFile) async {
//   Map<String, File> empty = {};
//   return _processExcelFile(excelFile, empty);
// }


//   // Process Excel file and match with images
//   Future<List<ProductData>> _processExcelFile(File excelFile, Map<String, File> images) async {
//     List<ProductData> products = [];

//     final bytes = await excelFile.readAsBytes();
//     final excel = Excel.decodeBytes(bytes);

//     for (var table in excel.tables.keys) {
//       final sheet = excel.tables[table]!;
      
//       // Skip header row (index 0)
//       for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
//         final row = sheet.rows[rowIndex];
        
//         if (row.isEmpty) continue;

//         // Parse product data according to your model
//         // Excel columns: itemCode, market, name, price, offerPrice, unit, stock, description, 
//         //                categoryId, hyperMarket, hyperMarketPrice, kgPrice, ctrPrice, pcsPrice, isHidden, images
        
//         String itemCode = row[0]?.value?.toString() ?? '';
//         String market = row[1]?.value?.toString() ?? '';
//         String name = row[2]?.value?.toString() ?? '';
//         double price = _parseDouble(row[3]?.value) ?? 0.0;
//         double? offerPrice = _parseDouble(row[4]?.value);
//         String unit = row[5]?.value?.toString() ?? '';
//         int stock = _parseInt(row[6]?.value);
//         String description = row[7]?.value?.toString() ?? '';
//         String categoryId = row[8]?.value?.toString() ?? '';
//         double? hyperMarket = _parseDouble(row[9]?.value);
//         double? hyperMarketPrice = _parseDouble(row[10]?.value);
//         double? kgPrice = _parseDouble(row[11]?.value);
//         double? ctrPrice = _parseDouble(row[12]?.value);
//         double? pcsPrice = _parseDouble(row[13]?.value);
//         bool isHidden = row[14]?.value?.toString().toLowerCase() == 'true';
//         String imageNames = row[15]?.value?.toString() ?? '';

//         if (name.isEmpty || itemCode.isEmpty) continue;

//         // Split image names by comma
//         List<String> imageFileNames = imageNames
//             .split(',')
//             .map((e) => e.trim())
//             .where((e) => e.isNotEmpty)
//             .toList();

//         // Match images
//         List<File> productImages = [];
//         for (var imageName in imageFileNames) {
//           if (images.containsKey(imageName)) {
//             productImages.add(images[imageName]!);
//           }
//         }

//         products.add(ProductData(
//           itemCode: itemCode,
//           market: market,
//           name: name,
//           price: price,
//           offerPrice: offerPrice,
//           unit: unit,
//           stock: stock,
//           description: description,
//           categoryId: categoryId,
//           hyperMarket: hyperMarket,
//           hyperMarketPrice: hyperMarketPrice,
//           kgPrice: kgPrice,
//           ctrPrice: ctrPrice,
//           pcsPrice: pcsPrice,
//           isHidden: isHidden,
//           imageFiles: productImages,
//         ));
//       }
//     }

//     return products;
//   }

//   double? _parseDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is num) return value.toDouble();
//     if (value is String) return double.tryParse(value);
//     return null;
//   }

//   int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value) ?? 0;
//     if (value is double) return value.toInt();
//     return 0;
//   }

//   void _showSuccessDialog(List<ProductData> products) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Upload Successful'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Processed ${products.length} products'),
//             SizedBox(height: 10),
//             Text('Total images: ${products.fold(0, (sum, p) => sum + p.imageFiles.length)}'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _saveProductsToFirestore(products);
//             },
//             child: Text('Upload to Firestore'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Save products to Firestore with Cloudinary image upload
//   Future<void> _saveProductsToFirestore(List<ProductData> products) async {
//     setState(() {
//       isProcessing = true;
//       uploadedCount = 0;
//       statusMessage = 'Starting bulk upload...';
//     });

//     try {
//       // TODO: Replace with your actual ProductProvider instance
//       // final productProvider = Provider.of<ProductProvider>(context, listen: false);

//       for (int i = 0; i < products.length; i++) {
//         final productData = products[i];
        
//         setState(() => statusMessage = 'Uploading product ${i + 1}/${products.length}: ${productData.name}');
        
//         // Create Product instance with temporary empty images list
//         final product = Product(
//           id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i', // Generate unique ID
//           itemCode: productData.itemCode,
//           market: productData.market,
//           name: productData.name,
//           price: productData.price,
//           offerPrice: productData.offerPrice,
//           unit: productData.unit,
//           stock: productData.stock,
//           description: productData.description,
//           images: [], // Will be filled by addProduct
//           categoryId: productData.categoryId,
//           hyperMarket: productData.hyperMarket,
//           hyperMarketPrice: productData.hyperMarketPrice,
//           kgPrice: productData.kgPrice,
//           ctrPrice: productData.ctrPrice,
//           pcsPrice: productData.pcsPrice,
//           isHidden: productData.isHidden,
//         );

//         // Call your existing addProduct function
//         // This will upload images to Cloudinary and save to Firestore
//         // await productProvider.addProduct(product, productData.imageFiles);

//         // ⚠️ UNCOMMENT THE LINE ABOVE AND COMMENT THE LINE BELOW WHEN INTEGRATING
//         await Future.delayed(Duration(milliseconds: 500)); // Simulate upload

//         setState(() => uploadedCount = i + 1);
//       }

//       setState(() {
//         isProcessing = false;
//         statusMessage = 'Successfully uploaded all ${products.length} products!';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Successfully uploaded ${products.length} products!'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 3),
//         ),
//       );

//       // Clear processed products after successful upload
//       setState(() => processedProducts = []);

//     } catch (e) {
//       setState(() {
//         isProcessing = false;
//         statusMessage = 'Error: Failed after uploading $uploadedCount products. Error: ${e.toString()}';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Upload failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 5),
//         ),
//       );
//     }
//   }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(title: Text('Bulk Product Upload')),
//     body: SingleChildScrollView(   // ✅ ADD THIS
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Instructions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     SizedBox(height: 10),
//                     Text('Excel/CSV Columns:', style: TextStyle(fontWeight: FontWeight.bold)),
//                     Text('itemCode, market, name, price, offerPrice, unit, stock, description, categoryId, hyperMarket, hyperMarketPrice, kgPrice, ctrPrice, pcsPrice, isHidden, images'),
//                     SizedBox(height: 10),
//                     Divider(),
//                     Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
//                     Text('• Prepare CSV or Excel'),
//                     Text('• Add images inside "images/" folder'),
//                     Text('• ZIP and upload'),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: isProcessing ? null : pickAndProcessZipOrCsvXlsxFile,
//               icon: Icon(Icons.upload_file),
//               label: Text('Select ZIP / CSV / Excel'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.all(16),
//               ),
//             ),
//             SizedBox(height: 20),

//             if (isProcessing)
//               Column(
//                 children: [
//                   LinearProgressIndicator(
//                     value: processedProducts.isNotEmpty && uploadedCount > 0
//                         ? uploadedCount / processedProducts.length
//                         : null,
//                   ),
//                   SizedBox(height: 10),
//                   Text('Uploaded: $uploadedCount / ${processedProducts.length}'),
//                 ],
//               ),

//             if (statusMessage.isNotEmpty)
//               Card(
//                 color: statusMessage.contains('Error') ? Colors.red.shade50 : Colors.green.shade50,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text(statusMessage),
//                 ),
//               ),

//             SizedBox(height: 20),

//             if (processedProducts.isNotEmpty && !isProcessing)
//               ListView.builder(
//                 shrinkWrap: true,        // ✅ prevents inner overflow
//                 physics: NeverScrollableScrollPhysics(), // ✅ handled by main scroll
//                 itemCount: processedProducts.length,
//                 itemBuilder: (context, index) {
//                   final p = processedProducts[index];
//                   return ListTile(
//                     title: Text(p.name),
//                     subtitle: Text('₹${p.price} | Stock: ${p.stock}'),
//                   );
//                 },
//               ),

//             SizedBox(height: 40), // optional spacing
//           ],
//         ),
//       ),
//     ),
//   );
// }

//   void _showProductDetails(ProductData product) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(product.name),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Item Code: ${product.itemCode}'),
//               Text('Market: ${product.market}'),
//               Text('Price: ₹${product.price}'),
//               if (product.offerPrice != null) Text('Offer Price: ₹${product.offerPrice}'),
//               Text('Unit: ${product.unit}'),
//               Text('Stock: ${product.stock}'),
//               Text('Category ID: ${product.categoryId}'),
//               if (product.hyperMarketPrice != null) Text('Hyper Market Price: ₹${product.hyperMarketPrice}'),
//               if (product.kgPrice != null) Text('KG Price: ₹${product.kgPrice}'),
//               if (product.ctrPrice != null) Text('CTR Price: ₹${product.ctrPrice}'),
//               if (product.pcsPrice != null) Text('PCS Price: ₹${product.pcsPrice}'),
//               Text('Hidden: ${product.isHidden}'),
//               SizedBox(height: 10),
//               Text('Description: ${product.description}'),
//               SizedBox(height: 10),
//               Text('Images (${product.imageFiles.length}):'),
//               SizedBox(height: 10),
//               ...product.imageFiles.map((img) => Padding(
//                 padding: EdgeInsets.only(bottom: 8),
//                 child: Image.file(img, height: 100),
//               )).toList(),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Temporary model to hold product data with File objects
// class ProductData {
//   final String itemCode;
//   final String market;
//   final String name;
//   final double price;
//   final double? offerPrice;
//   final String unit;
//   final int stock;
//   final String description;
//   final String categoryId;
//   final double? hyperMarket;
//   final double? hyperMarketPrice;
//   final double? kgPrice;
//   final double? ctrPrice;
//   final double? pcsPrice;
//   final bool isHidden;
//   final List<File> imageFiles;

//   ProductData({
//     required this.itemCode,
//     required this.market,
//     required this.name,
//     required this.price,
//     this.offerPrice,
//     required this.unit,
//     required this.stock,
//     required this.description,
//     required this.categoryId,
//     this.hyperMarket,
//     this.hyperMarketPrice,
//     this.kgPrice,
//     this.ctrPrice,
//     this.pcsPrice,
//     required this.isHidden,
//     required this.imageFiles,
//   });
// }

// // Your existing Product model (reference - already in your code)
// class Product {
//   String id;
//   String name;
//   double price;
//   double? offerPrice;
//   String unit;
//   int stock;
//   String description;
//   List<String> images;
//   String categoryId;
//   double? hyperMarket;
//   String market;
//   String itemCode;
//   double? hyperMarketPrice;
//   double? kgPrice;
//   double? ctrPrice;
//   double? pcsPrice;
//   bool isHidden;

//   Product({
//     required this.itemCode,
//     required this.market,
//     required this.id,
//     required this.name,
//     required this.price,
//     this.offerPrice,
//     required this.unit,
//     required this.stock,
//     required this.description,
//     required this.images,
//     required this.categoryId,
//     this.hyperMarket,
//     this.hyperMarketPrice,
//     this.kgPrice,
//     this.ctrPrice,
//     this.pcsPrice,
//     this.isHidden = false,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'itemCode': itemCode,
//       'market': market,
//       'hyperPrice': hyperMarket,
//       'id': id,
//       'name': name,
//       'price': price,
//       'offerPrice': offerPrice,
//       'unit': unit,
//       'stock': stock,
//       'description': description,
//       'images': images,
//       'categoryId': categoryId,
//       'hyperMarketPrice': hyperMarketPrice,
//       'kgPrice': kgPrice,
//       'ctrPrice': ctrPrice,
//       'pcsPrice': pcsPrice,
//       'isHidden': isHidden,
//     };
//   }
// }