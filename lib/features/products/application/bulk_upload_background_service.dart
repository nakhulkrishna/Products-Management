import 'package:flutter/foundation.dart';
import 'package:products_catelogs/features/products/presentation/widgets/add_edit_product_form_view.dart';

class BulkUploadStatus {
  final bool isRunning;
  final int total;
  final int completed;
  final int success;
  final int failed;
  final String message;
  final List<String> errors;

  const BulkUploadStatus({
    required this.isRunning,
    required this.total,
    required this.completed,
    required this.success,
    required this.failed,
    required this.message,
    required this.errors,
  });

  const BulkUploadStatus.idle()
    : isRunning = false,
      total = 0,
      completed = 0,
      success = 0,
      failed = 0,
      message = 'No active upload',
      errors = const [];
}

class BulkUploadBackgroundService {
  BulkUploadBackgroundService._();
  static final BulkUploadBackgroundService instance =
      BulkUploadBackgroundService._();

  final ValueNotifier<BulkUploadStatus> status =
      ValueNotifier<BulkUploadStatus>(const BulkUploadStatus.idle());

  bool get isRunning => status.value.isRunning;

  Future<void> start({
    required List<ProductFormResult> items,
    required Future<void> Function(ProductFormResult item, int index) uploader,
  }) async {
    if (items.isEmpty) {
      status.value = const BulkUploadStatus(
        isRunning: false,
        total: 0,
        completed: 0,
        success: 0,
        failed: 0,
        message: 'No rows to upload',
        errors: [],
      );
      return;
    }
    if (isRunning) {
      throw StateError('Bulk upload already running.');
    }

    status.value = BulkUploadStatus(
      isRunning: true,
      total: items.length,
      completed: 0,
      success: 0,
      failed: 0,
      message: 'Bulk upload started',
      errors: const [],
    );

    var success = 0;
    var failed = 0;
    final errors = <String>[];

    for (int i = 0; i < items.length; i++) {
      try {
        await uploader(items[i], i);
        success++;
      } catch (e) {
        failed++;
        if (errors.length < 100) {
          errors.add('Row ${i + 1}: $e');
        }
      }

      status.value = BulkUploadStatus(
        isRunning: true,
        total: items.length,
        completed: i + 1,
        success: success,
        failed: failed,
        message: 'Uploading ${i + 1}/${items.length}',
        errors: List<String>.unmodifiable(errors),
      );
    }

    status.value = BulkUploadStatus(
      isRunning: false,
      total: items.length,
      completed: items.length,
      success: success,
      failed: failed,
      message: 'Upload complete. Success: $success, Failed: $failed',
      errors: List<String>.unmodifiable(errors),
    );
  }
}
