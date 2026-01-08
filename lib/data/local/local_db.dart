// import 'dart:developer';

// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// import '../../models/job_model.dart';

// class JobDatabase {
//   static final JobDatabase instance = JobDatabase._init();
//   static Database? _database;

//   JobDatabase._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('jobs.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String fileName) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, fileName);
//     return await openDatabase(
//       path,
//       version: 3,
//       onCreate: _createDB,
//       onUpgrade: _migrateDB,
//     );
//   }

//   Future _createDB(Database db, int version) async {
//     await db.execute('''
//     CREATE TABLE jobs (
//       jobId TEXT PRIMARY KEY,
//       jobType TEXT,
//       jobStatus TEXT,
//       bookingRef TEXT,
//       customerName TEXT,
//       airportId TEXT,
//       terminalId TEXT,
//       flightNo TEXT,
//       dateTime TEXT,
//       vehicle TEXT,
//       parkingYardId TEXT,
//       notes TEXT,
//       driverId TEXT,
//       terminalLat REAL,
//       terminalLng REAL,
//       jobCreatedTime TEXT,
//       jobStartedTime TEXT,
//       jobCompletedTime TEXT,
//       vehicleInfoStartTime TEXT,
//       vehicleInfoEndTime TEXT,
//       imagesInfoStartTime TEXT,
//       imagesInfoEndTime TEXT,
//       consentStartTime TEXT,
//       consentEndTime TEXT,
//       images TEXT,
//       video TEXT,
//       valuables TEXT,
//       signature TEXT
//     )
//     ''');
//   }

//   // Migrate existing database to new schema
//   Future<void> _migrateDB(Database db, int oldVersion, int newVersion) async {
//     if (oldVersion < 2) {
//       // Add new columns if they don't exist (v1 to v2 migration)
//       try {
//         await db.execute('ALTER TABLE jobs ADD COLUMN jobType TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN bookingRef TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN customerName TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN airportId TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN terminalId TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN flightNo TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN dateTime TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN vehicle TEXT');
//         await db.execute('ALTER TABLE jobs ADD COLUMN parkingYardId TEXT');
//       } catch (e) {
//         // Columns might already exist, ignore
//         log('Migration v1->v2: $e');
//       }
//     }

//     if (oldVersion < 3) {
//       // Remove vehicleType and year columns (v2 to v3 migration)
//       // Note: SQLite doesn't support DROP COLUMN directly, so we'll recreate the table
//       try {
//         // Create new table without vehicleType and year
//         await db.execute('''
//         CREATE TABLE jobs_new (
//           jobId TEXT PRIMARY KEY,
//           jobType TEXT,
//           jobStatus TEXT,
//           bookingRef TEXT,
//           customerName TEXT,
//           airportId TEXT,
//           terminalId TEXT,
//           flightNo TEXT,
//           dateTime TEXT,
//           vehicle TEXT,
//           parkingYardId TEXT,
//           notes TEXT,
//           driverId TEXT,
//           terminalLat REAL,
//           terminalLng REAL,
//           jobCreatedTime TEXT,
//           jobStartedTime TEXT,
//           jobCompletedTime TEXT,
//           vehicleInfoStartTime TEXT,
//           vehicleInfoEndTime TEXT,
//           imagesInfoStartTime TEXT,
//           imagesInfoEndTime TEXT,
//           consentStartTime TEXT,
//           consentEndTime TEXT,
//           images TEXT,
//           video TEXT,
//           valuables TEXT,
//           signature TEXT
//         )
//         ''');

//         // Copy data from old table to new table (excluding vehicleType and year)
//         await db.execute('''
//         INSERT INTO jobs_new (
//           jobId, jobType, jobStatus, bookingRef, customerName, airportId, 
//           terminalId, flightNo, dateTime, vehicle, parkingYardId, notes,
//           driverId, terminalLat, terminalLng, jobCreatedTime, jobStartedTime,
//           jobCompletedTime, vehicleInfoStartTime, vehicleInfoEndTime,
//           imagesInfoStartTime, imagesInfoEndTime, consentStartTime, consentEndTime,
//           images, video, valuables, signature
//         )
//         SELECT 
//           jobId, jobType, jobStatus, bookingRef, customerName, airportId,
//           terminalId, flightNo, dateTime, vehicle, parkingYardId, notes,
//           driverId, terminalLat, terminalLng, jobCreatedTime, jobStartedTime,
//           jobCompletedTime, vehicleInfoStartTime, vehicleInfoEndTime,
//           imagesInfoStartTime, imagesInfoEndTime, consentStartTime, consentEndTime,
//           images, video, valuables, signature
//         FROM jobs
//         ''');

//         // Drop old table
//         await db.execute('DROP TABLE jobs');

//         // Rename new table to jobs
//         await db.execute('ALTER TABLE jobs_new RENAME TO jobs');
//       } catch (e) {
//         // If migration fails, log error but continue
//         log('Migration v2->v3: $e');
//       }
//     }
//   }

//   Future<void> insertJob(JobModel job) async {
//     final db = await instance.database;
//     await db.insert('jobs', job.toMap());
//   }

//   Future<List<JobModel>> getAllJobs() async {
//     final db = await instance.database;
//     final maps = await db.query('jobs', orderBy: 'jobCreatedTime DESC');
//     return maps.map((e) => JobModel.fromMap(e)).toList();
//   }

//   Future<void> updateJobStatus(
//     String jobId,
//     String newStatus, {
//     DateTime? startedTime,
//     DateTime? completedTime,
//   }) async {
//     final db = await instance.database;
//     await db.update(
//       'jobs',
//       {
//         'jobStatus': newStatus,
//         'jobStartedTime': startedTime?.toIso8601String(),
//         'jobCompletedTime': completedTime?.toIso8601String(),
//       },
//       where: 'jobId = ?',
//       whereArgs: [jobId],
//     );
//   }

//   Future<void> startJob(String jobId) async {
//     await JobDatabase.instance.updateJobStatus(
//       jobId,
//       'ontheway',
//       startedTime: DateTime.now(),
//     );
//   }

//   Future<void> completeJob(String jobId) async {
//     await JobDatabase.instance.updateJobStatus(
//       jobId,
//       'parked',
//       completedTime: DateTime.now(),
//     );
//   }

//   Future<void> updateJobById(JobModel updatedJob) async {
//     try {
//       final db = await instance.database;

//       await db.update(
//         'jobs',
//         updatedJob.toMap(), // full replacement data
//         where: 'jobId = ?',
//         whereArgs: [updatedJob.jobId],
//       );
//     } catch (e) {
//       // TODO
//       log("errir $e");
//     }
//   }
// }
