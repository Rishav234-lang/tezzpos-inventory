import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';

final profileUserProvider = FutureProvider.autoDispose<User>((ref) async {
  final dio = ref.watch(dioProvider).dio;
  final response = await dio.get(ApiConstants.me);
  final userData = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};
  return UserModel.fromJson(userData).toEntity();
});
