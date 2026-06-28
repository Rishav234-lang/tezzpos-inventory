import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<Either<Failure, Map<String, dynamic>>> getPurchases({
    int page,
    int limit,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
    String? sortOrder,
  });
  Future<Either<Failure, Purchase>> getPurchaseById(String id);
  Future<Either<Failure, Purchase>> createPurchase(Map<String, dynamic> data);
  Future<Either<Failure, Purchase>> updatePurchase(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deletePurchase(String id);
  Future<Either<Failure, void>> recordVendorPayment(Map<String, dynamic> data);
}
