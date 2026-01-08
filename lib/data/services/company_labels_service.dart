import 'dart:developer' as developer;

import 'package:driver_tracking_airport/data/remote/repositories/getCompanyLables.dart';
import 'package:get/get.dart';

/// Service to manage company labels (job type labels)
/// Stores labels fetched from API and provides methods to get label for job type
class CompanyLabelsService extends GetxService {
  final GetCompanyLabelsRepository _repository = GetCompanyLabelsRepository();

  // Store labels as key-value pairs (e.g., "Receive": "Get", "Shift": "Shift")
  final RxMap<String, String> _labels = <String, String>{}.obs;

  // Track if labels have been loaded
  final RxBool isLoaded = false.obs;

  /// Get the label for a job type
  /// Returns the custom label if available, otherwise returns the original job type
  String getLabelForJobType(String? jobType) {
    if (jobType == null || jobType.isEmpty) {
      return 'UNKNOWN';
    }

    // If labels haven't been loaded yet, return the original job type in uppercase
    if (!isLoaded.value || _labels.isEmpty) {
      return jobType.toUpperCase();
    }

    // Try to find matching key (case-insensitive)
    final jobTypeUpper = jobType.toUpperCase();
    for (final entry in _labels.entries) {
      if (entry.key.toUpperCase() == jobTypeUpper) {
        return entry.value;
      }
    }

    // If no match found, return the original job type in uppercase
    return jobTypeUpper;
  }

  /// Get all labels
  Map<String, String> get labels => Map<String, String>.from(_labels);

  /// Fetch and store company labels from API
  Future<void> fetchLabels() async {
    try {
      isLoaded.value = false;
      final labels = await _repository.getCompanyLabels();
      _labels.clear();
      _labels.addAll(labels);
      isLoaded.value = true;
      developer.log('Company labels loaded: $labels');
    } catch (e) {
      developer.log('Failed to fetch company labels: $e');
      // Keep existing labels if fetch fails
      isLoaded.value = false;
      rethrow;
    }
  }

  /// Initialize labels (call this on app start)
  Future<void> init() async {
    try {
      await fetchLabels();
    } catch (e) {
      developer.log('Error initializing company labels: $e');
      // Continue even if labels fail to load - will use default job types
    }
  }
}
