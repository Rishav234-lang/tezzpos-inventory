import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sale.dart';
import '../entities/sale_return.dart';

abstract class SaleRepository {
  Future<Either<Failure, List<Sale>>> getSales({
    String? customerId,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page,
    int limit,
  });
  Future<Either<Failure, Sale>> getSaleById(String id);
  Future<Either<Failure, Sale>> createSale(Map<String, dynamic> data);
  Future<Either<Failure, Sale>> updateSalePayment(String id, Map<String, dynamic> data);
  Future<Either<Failure, List<Sale>>> searchSalesByInvoice(String invoiceNumber);

  Future<Either<Failure, List<SaleReturn>>> getSaleReturns({int page, int limit});
  Future<Either<Failure, SaleReturn>> getSaleReturnById(String id);
  Future<Either<Failure, SaleReturn>> createSaleReturn(Map<String, dynamic> data);
}
