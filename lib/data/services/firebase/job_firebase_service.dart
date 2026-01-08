import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracking_airport/models/job_model.dart';

/// Firebase service for job operations
/// Optimized to prevent duplicate writes and unnecessary updates
class JobFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'jobs';

  /// Start a job - Create Firestore document with status 'ontheway'
  /// Returns document ID
  /// Prevents duplicate creation by checking if document exists
  Future<String> startJob(JobModel job, {required String driverId}) async {
    try {
      // Use jobId as document ID to prevent duplicates
      final docRef = _firestore.collection(_collectionName).doc(job.jobId);

      // Check if document already exists
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists - just update status if needed
        if (docSnapshot.data()?['jobStatus'] != 'ontheway') {
          await docRef.update({
            'jobStatus': 'ontheway',
            'driverId': driverId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        return job.jobId;
      }

      // Create new document with full job model
      final jobData = job
          .copyWith(
            driverId: driverId,
            jobStatus: 'ontheway',
            jobAcceptedTime: DateTime.now(),
          )
          .toFirestore();

      // Add server timestamp
      jobData['createdAt'] = FieldValue.serverTimestamp();
      jobData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(jobData);
      return job.jobId;
    } catch (e) {
      throw Exception('Failed to start job in Firebase: $e');
    }
  }

  /// Update job data incrementally
  /// Only updates provided fields to avoid unnecessary writes
  Future<void> updateJob(
    String jobId, {
    Map<String, dynamic>? updates,
    JobModel? fullJob,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(jobId);

      // Check if document exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Job document does not exist');
      }

      if (updates != null) {
        // Incremental update - only update provided fields
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(updates);
      } else if (fullJob != null) {
        // Full update - replace entire document
        final jobData = fullJob.toFirestore();
        jobData['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.set(jobData, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to update job in Firebase: $e');
    }
  }

  /// Update job status
  Future<void> updateJobStatus(
    String jobId,
    String newStatus, {
    DateTime? completedTime,
  }) async {
    try {
      final updates = <String, dynamic>{
        'jobStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'parked' && completedTime != null) {
        updates['jobCompletedTime'] = completedTime.toIso8601String();
      }

      await updateJob(jobId, updates: updates);
    } catch (e) {
      throw Exception('Failed to update job status: $e');
    }
  }

  /// Get ongoing job for a driver
  /// Returns the job document if driver has an active job
  Future<JobModel?> getOngoingJob(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('driverId', isEqualTo: driverId)
          .where('jobStatus', whereIn: ['ontheway', 'started'])
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final docData = querySnapshot.docs.first.data();
      return JobModel.fromFirestore(docData);
    } catch (e) {
      throw Exception('Failed to get ongoing job: $e');
    }
  }

  /// Listen to ongoing job changes in real-time
  Stream<JobModel?> streamOngoingJob(String driverId) {
    return _firestore
        .collection(_collectionName)
        .where('driverId', isEqualTo: driverId)
        .where('jobStatus', whereIn: ['ontheway', 'started'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return JobModel.fromFirestore(snapshot.docs.first.data());
        });
  }

  /// Update vehicle info step
  Future<void> updateVehicleInfo(
    String jobId, {
    DateTime? startTime,
    DateTime? endTime,
    VehicleInfo? vehicle,
    String? plate,
  }) async {
    final updates = <String, dynamic>{};

    if (startTime != null) {
      updates['vehicleInfoStartTime'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      updates['vehicleInfoEndTime'] = endTime.toIso8601String();
    }
    if (vehicle != null) {
      updates['vehicle'] = vehicle.toJson();
    }
    if (plate != null) {
      // Update vehicle regNo if plate is provided
      updates['vehicle.RegNo'] = plate;
    }

    if (updates.isNotEmpty) {
      await updateJob(jobId, updates: updates);
    }
  }

  /// Update images step
  Future<void> updateImagesInfo(
    String jobId, {
    DateTime? startTime,
    DateTime? endTime,
    List<String>? images,
    String? video,
  }) async {
    final updates = <String, dynamic>{};

    if (startTime != null) {
      updates['imagesInfoStartTime'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      updates['imagesInfoEndTime'] = endTime.toIso8601String();
    }
    if (images != null) {
      updates['images'] = images;
    }
    if (video != null) {
      updates['video'] = video;
    }

    if (updates.isNotEmpty) {
      await updateJob(jobId, updates: updates);
    }
  }

  /// Update consent step
  Future<void> updateConsentInfo(
    String jobId, {
    DateTime? startTime,
    DateTime? endTime,
    String? signature,
    String? valuables,
  }) async {
    final updates = <String, dynamic>{};

    if (startTime != null) {
      updates['consentStartTime'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      updates['consentEndTime'] = endTime.toIso8601String();
    }
    if (signature != null) {
      updates['signature'] = signature;
    }
    if (valuables != null) {
      updates['valuables'] = valuables;
    }

    if (updates.isNotEmpty) {
      await updateJob(jobId, updates: updates);
    }
  }

  /// Complete job
  Future<void> completeJob(String jobId) async {
    await updateJobStatus(jobId, 'parked', completedTime: DateTime.now());
  }

  /// Delete job document (if needed)
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection(_collectionName).doc(jobId).delete();
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }
}
