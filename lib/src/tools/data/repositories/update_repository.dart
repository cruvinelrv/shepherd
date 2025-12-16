import '../../domain/repositories/update_repository.dart';
import '../datasources/pub_dev_datasource.dart';
import '../datasources/update_cache_datasource.dart';

/// Repository implementation for update checking
class UpdateRepositoryImpl implements UpdateRepository {
  final PubDevDatasource _pubDevDatasource;
  final UpdateCacheDatasource _cacheDatasource;

  UpdateRepositoryImpl(this._pubDevDatasource, this._cacheDatasource);

  @override
  Future<String?> getLatestVersion(String packageName) async {
    return await _pubDevDatasource.getLatestVersion(packageName);
  }

  @override
  Future<DateTime?> getLastCheckTime() async {
    return await _cacheDatasource.getLastCheckTime();
  }

  @override
  Future<void> saveLastCheckTime(DateTime time) async {
    await _cacheDatasource.saveLastCheckTime(time);
  }
}
