import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/repositories/seller_repository.dart';

class GetSellerDashboardUseCase {
  final SellerRepository repository;

  const GetSellerDashboardUseCase(this.repository);

  Future<Result<SellerDashboard>> call() {
    return repository.getDashboard();
  }
}
