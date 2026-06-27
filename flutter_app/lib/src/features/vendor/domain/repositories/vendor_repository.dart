import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vendor.dart';

abstract class VendorRepository {
  Future<Either<Failure, List<Vendor>>> getVendors({
    String? search,
    int page,
    int limit,
  });
  Future<Either<Failure, Vendor>> getVendorById(String id);
  Future<Either<Failure, Vendor>> createVendor(Map<String, dynamic> data);
  Future<Either<Failure, Vendor>> updateVendor(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteVendor(String id);
  Future<Either<Failure, Map<String, dynamic>>> getVendorLedger(String id);
}
