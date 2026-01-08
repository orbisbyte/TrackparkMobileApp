import 'package:driver_tracking_airport/Screens/Homepge/controller/dashboard_controller.dart';
import 'package:driver_tracking_airport/data/services/company_labels_service.dart';
import 'package:driver_tracking_airport/models/job_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/message_helper.dart';

/// Incoming Jobs Section Widget
class IncomingJobsSection extends StatelessWidget {
  const IncomingJobsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<DashBoardController>();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(controller),
          const SizedBox(height: 12),
          _buildJobsList(controller),
        ],
      );
    });
  }

  /// Build section header with refresh button
  Widget _buildSectionHeader(DashBoardController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Incoming Jobs',
          style: Theme.of(
            Get.context!,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 20,
            color: controller.isLoadingIncomingJobs.value
                ? Colors.grey
                : Colors.blue,
          ),
          onPressed: controller.isLoadingIncomingJobs.value
              ? null
              : () => controller.loadIncomingJobs(),
        ),
      ],
    );
  }

  /// Build jobs list or empty/loading state
  Widget _buildJobsList(DashBoardController controller) {
    if (controller.isLoadingIncomingJobs.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.incomingJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No incoming jobs at the moment',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.incomingJobs.length,
      itemBuilder: (context, index) {
        final job = controller.incomingJobs[index];
        return IncomingJobCard(job: job);
      },
    );
  }
}

/// Incoming Job Card Widget - Minimal Design
class IncomingJobCard extends StatelessWidget {
  final JobModel job;

  const IncomingJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    // Get label from company labels service
    final labelsService = Get.find<CompanyLabelsService>();
    final jobTypeLabel = labelsService.getLabelForJobType(job.jobType);
    final jobTypeIcon = job.isParkingJob
        ? Icons.local_parking
        : job.isDeliveryJob
        ? Icons.delivery_dining
        : job.isShiftJob
        ? Icons.directions_run
        : Icons.help;
    final jobTypeColor = job.isParkingJob
        ? Colors.blue
        : job.isDeliveryJob
        ? Colors.orange
        : job.isShiftJob
        ? Colors.green
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Job Type Badge with Job ID
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: jobTypeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(jobTypeIcon, size: 14, color: jobTypeColor),
                      const SizedBox(width: 6),
                      Text(
                        '$jobTypeLabel • ${job.jobId}',
                        style: TextStyle(
                          color: jobTypeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Countdown Timer (if dateTime available)
                Text(
                  JobDetailsBottomSheet._formatDateTime(job.dateTime!),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                // if (job.dateTime != null)
                //   CountdownTimerWidget(
                //     targetDateTime: job.dateTime,
                //     uniqueId: job.jobId, // Use jobId as unique identifier
                //     textStyle: const TextStyle(
                //       fontSize: 13,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
              ],
            ),
            const SizedBox(height: 16),
            // FROM/TO Location Information (based on job type)
            _buildLocationInfo(job),

            // Vehicle Details
            if (job.vehicle != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${job.vehicle!.colour ?? ''} ${job.vehicle!.make ?? ''} ${job.vehicle!.model ?? ''} • ${job.vehicle!.regNo ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Action Buttons
            if (job.jobStatus?.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(child: _buildSeeDetailsButton(context)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildAcceptButton()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build location information (FROM/TO) based on job type
  Widget _buildLocationInfo(JobModel job) {
    // Determine FROM and TO based on job type
    // Determine FROM and TO based on job type
    String? fromId;
    String? fromName;
    IconData fromIcon;
    String fromLabel;
    String? toId;
    String? toName;
    IconData toIcon;
    String toLabel;
    if (job.isParkingJob) {
      // RECEIVE: FROM = Terminal, TO = Yard
      fromId = job.terminalId;
      fromName = job.terminalName;
      fromIcon = Icons.location_on;
      fromLabel = 'Terminal';
      toId = job.toYardId;
      toName = job.toYardName;
      toIcon = Icons.local_parking;
      toLabel = 'Yard';
    } else if (job.isDeliveryJob) {
      // RETURN: FROM = Yard, TO = Terminal
      fromId = job.fromYardId;
      fromName = job.fromYardName;
      fromIcon = Icons.local_parking;
      fromLabel = 'Yard';
      toId = job.terminalId;
      toName = job.terminalName;
      toIcon = Icons.location_on;
      toLabel = 'Terminal';
    } else if (job.isShiftJob) {
      // SHIFT: FROM = Yard, TO = Empty (no second yard info)
      fromId = job.fromYardId;
      fromName = job.fromYardName;
      fromIcon = Icons.local_parking;
      fromLabel = 'Yard';
      toId = job.toYardId;
      toName = job.toYardName;
      toIcon = Icons.local_parking;
      toLabel = 'Yard';
    } else {
      // Unknown job type - show nothing
      return const SizedBox.shrink();
    }

    // Only show if we have at least FROM information
    if (fromId == null && fromName == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FROM/TO Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // FROM Label - Left Aligned
            if (fromId != null || fromName != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'FROM',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // TO Label - Right Aligned
            if (toId != null || toName != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TO',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // // FROM/TO IDs Row
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     // FROM Section - Left Aligned (Icon + Text)
        //     if (fromId != null || fromName != null)
        //       Expanded(
        //         child: Row(
        //           children: [
        //             Icon(fromIcon, size: 16, color: Colors.grey.shade600),
        //             const SizedBox(width: 6),
        //             Flexible(
        //               child: Text(
        //                 "$fromLabel ${fromId ?? ''}",
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   color: Colors.grey.shade700,
        //                   fontWeight: FontWeight.w500,
        //                 ),
        //                 maxLines: 1,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     // TO Section - Right Aligned (Text + Icon)
        //     if (toId != null || toName != null)
        //       Expanded(
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.end,
        //           children: [
        //             Flexible(
        //               child: Text(
        //                 "$toLabel ${toId ?? ''}",
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   color: Colors.grey.shade700,
        //                   fontWeight: FontWeight.w500,
        //                 ),
        //                 maxLines: 1,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
        //             ),
        //             const SizedBox(width: 6),
        //             Icon(toIcon, size: 16, color: Colors.grey.shade600),
        //           ],
        //         ),
        //       ),
        //   ],
        // ),
        // FROM/TO Names Row (if available and different from IDs)
        if ((fromName != null && fromName != fromId) ||
            (toName != null && toName != toId)) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FROM Name - Left Aligned (Icon + Text)
              if (fromName != null && fromName != fromId)
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fromName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // TO Name - Right Aligned (Text + Icon)
              if (toName != null && toName != toId)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          toName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build See Details button
  Widget _buildSeeDetailsButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _showJobDetailsBottomSheet(context),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text(
        'Details',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  /// Build Accept Job button
  Widget _buildAcceptButton() {
    return Obx(() {
      final controller = Get.find<DashBoardController>();
      final hasOngoing = controller.hasOngoingJob;
      final isThisJobLoading = controller.startingJobId.value == job.jobId;
      final jobTypeColor = job.isParkingJob ? Colors.blue : Colors.orange;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (isThisJobLoading || hasOngoing)
              ? () => MessageHelper.showWarning(
                  'You already have an ongoing job. Please complete it first.',
                )
              : () => controller.acceptJob(job),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasOngoing ? Colors.grey.shade400 : jobTypeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: isThisJobLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }

  /// Show job details bottom sheet
  void _showJobDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobDetailsBottomSheet(job: job),
    );
  }
}

/// Job Details Bottom Sheet
class JobDetailsBottomSheet extends StatelessWidget {
  final JobModel job;

  const JobDetailsBottomSheet({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    // Get label from company labels service
    final labelsService = Get.find<CompanyLabelsService>();
    final jobTypeLabel = labelsService.getLabelForJobType(job.jobType);

    final jobTypeColor = job.isParkingJob
        ? Colors.blue
        : job.isDeliveryJob
        ? Colors.orange
        : job.isShiftJob
        ? Colors.green
        : Colors.grey;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: jobTypeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: jobTypeColor, width: 1.5),
                        ),
                        child: Text(
                          jobTypeLabel,
                          style: TextStyle(
                            color: jobTypeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Booking Information
                      _buildSectionTitle('Booking Information'),
                      const SizedBox(height: 12),
                      if (job.bookingRef != null)
                        _buildDetailItem(
                          Icons.confirmation_number,
                          'Booking Reference',
                          job.bookingRef!,
                        ),
                      if (job.customerName != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailItem(
                          Icons.person,
                          'Customer Name',
                          job.customerName!,
                        ),
                      ],
                      if (job.dateTime != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailItem(
                          Icons.access_time,
                          'Scheduled Time',
                          _formatDateTime(job.dateTime!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Vehicle Information
                      if (job.vehicle != null) ...[
                        _buildSectionTitle('Vehicle Information'),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          Icons.directions_car,
                          'Vehicle',
                          '${job.vehicle!.make ?? 'N/A'} ${job.vehicle!.model ?? ''}',
                        ),
                        if (job.vehicle!.regNo != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailItem(
                            Icons.confirmation_number,
                            'Registration Number',
                            job.vehicle!.regNo!,
                          ),
                        ],
                        if (job.vehicle!.colour != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailItem(
                            Icons.palette,
                            'Colour',
                            job.vehicle!.colour!,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      // Location Information (FROM/TO based on job type)
                      _buildLocationInfoSection(),
                      // Additional Information (Airport ID, Flight No)
                      if (job.airportId != null || job.flightNo != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Additional Information'),
                        const SizedBox(height: 12),
                        if (job.airportId != null) ...[
                          _buildDetailItem(
                            Icons.flight_takeoff,
                            'Airport ID',
                            job.airportId!,
                          ),
                        ],
                        if (job.flightNo != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailItem(
                            Icons.flight,
                            'Flight Number',
                            job.flightNo!,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      // Job Status
                      _buildSectionTitle('Job Status'),
                      const SizedBox(height: 12),
                      _buildStatusCard(),
                      // Notes
                      if (job.notes != null &&
                          job.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Notes'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            job.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build location information section (FROM/TO) based on job type
  Widget _buildLocationInfoSection() {
    // Determine FROM and TO based on job type
    String? fromId;
    String? fromName;
    IconData fromIcon;
    String fromLabel;
    String? toId;
    String? toName;
    IconData toIcon;
    String toLabel;

    if (job.isParkingJob) {
      // RECEIVE: FROM = Terminal, TO = Yard
      fromId = job.terminalId;
      fromName = job.terminalName;
      fromIcon = Icons.location_on;
      fromLabel = 'Terminal';
      toId = job.toYardId;
      toName = job.toYardName;
      toIcon = Icons.local_parking;
      toLabel = 'Yard';
    } else if (job.isDeliveryJob) {
      // RETURN: FROM = Yard, TO = Terminal
      fromId = job.fromYardId;
      fromName = job.fromYardName;
      fromIcon = Icons.local_parking;
      fromLabel = 'Yard';
      toId = job.terminalId;
      toName = job.terminalName;
      toIcon = Icons.location_on;
      toLabel = 'Terminal';
    } else if (job.isShiftJob) {
      // SHIFT: FROM = Yard, TO = Empty (no second yard info)
      fromId = job.fromYardId;
      fromName = job.fromYardName;
      fromIcon = Icons.local_parking;
      fromLabel = 'Yard';
      toId = job.toYardId;
      toName = job.toYardName;
      toIcon = Icons.local_parking;
      toLabel = 'Yard';
    } else {
      // Unknown job type - show nothing
      return const SizedBox.shrink();
    }

    // Only show if we have at least FROM information
    if (fromId == null && fromName == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location Information'),
        const SizedBox(height: 12),
        // FROM Section
        if (fromId != null || fromName != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(fromIcon, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'FROM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // if (fromId != null)
                //   Text(
                //     '$fromLabel ID: $fromId',
                //     style: const TextStyle(
                //       fontSize: 14,
                //       fontWeight: FontWeight.w600,
                //       color: Color(0xFF1E293B),
                //     ),
                //   ),
                if (fromName != null && fromName != fromId) ...[
                  if (fromId != null) const SizedBox(height: 4),
                  Text(
                    fromName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
        // TO Section
        if (toId != null || toName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(toIcon, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'TO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // if (toId != null)
                //   Text(
                //     '$toLabel ID: $toId',
                //     style: const TextStyle(
                //       fontSize: 14,
                //       fontWeight: FontWeight.w600,
                //       color: Color(0xFF1E293B),
                //     ),
                //   ),
                if (toName != null && toName != toId) ...[
                  if (toId != null) const SizedBox(height: 4),
                  Text(
                    toName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo['color'].withOpacity(0.1),
            statusInfo['color'].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusInfo['color'],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              statusInfo['icon'] as IconData,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusInfo['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (job.jobStatus?.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case 'ontheway':
        statusColor = Colors.blue;
        statusLabel = 'On The Way';
        statusIcon = Icons.directions_car;
        break;
      case 'started':
        statusColor = Colors.green;
        statusLabel = 'Started';
        statusIcon = Icons.play_circle;
        break;
      case 'parked':
      case 'delivered':
        statusColor = Colors.grey;
        statusLabel = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = job.jobStatus ?? 'Pending';
        statusIcon = Icons.schedule;
    }

    return {'color': statusColor, 'label': statusLabel, 'icon': statusIcon};
  }

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMMM dd, yyyy • HH:mm').format(dateTime);
  }
}
