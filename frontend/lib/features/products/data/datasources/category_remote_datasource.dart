import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';

/// Contract for category remote data interactions.
abstract interface class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryDetails(String id);
}

/// Dio implementation for CategoryRemoteDataSource.
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  const CategoryRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dioClient.get<List<dynamic>>('/api/v1/categories');
    final data = response.data ?? [];
    return data
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryModel> getCategoryDetails(String id) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/api/v1/categories/$id',
    );
    return CategoryModel.fromJson(response.data!);
  }
}
