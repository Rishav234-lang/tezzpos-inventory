import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers({
    String? search,
    int page,
    int limit,
  });
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, Customer>> createCustomer(Map<String, dynamic> data);
  Future<Either<Failure, Customer>> updateCustomer(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, Map<String, dynamic>>> getCustomerLedger(String id);
  Future<Either<Failure, Map<String, dynamic>>> getCustomerSales(String id, {int page, int limit});
  Future<Either<Failure, void>> receivePayment(Map<String, dynamic> data);
}
