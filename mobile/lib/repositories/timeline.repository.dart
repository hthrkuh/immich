import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/album.entity.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/infrastructure/entities/user.entity.dart';
import 'package:immich_mobile/interfaces/timeline.interface.dart';
import 'package:immich_mobile/providers/db.provider.dart';
import 'package:immich_mobile/repositories/database.repository.dart';
import 'package:immich_mobile/utils/hash.dart';
import 'package:immich_mobile/widgets/asset_grid/asset_grid_data_structure.dart';
import 'package:openapi/api.dart';
import 'package:isar/isar.dart';

final timelineRepositoryProvider =
    Provider((ref) => TimelineRepository(ref.watch(dbProvider)));

class TimelineRepository extends DatabaseRepository
    implements ITimelineRepository {
  TimelineRepository(super.db);

  @override
  Future<List<String>> getTimelineUserIds(String id) {
    return db.users
        .filter()
        .inTimelineEqualTo(true)
        .or()
        .idEqualTo(id)
        .idProperty()
        .findAll();
  }

  @override
  Stream<List<String>> watchTimelineUsers(String id) {
    return db.users
        .filter()
        .inTimelineEqualTo(true)
        .or()
        .idEqualTo(id)
        .idProperty()
        .watch();
  }

  @override
  Stream<RenderList> watchArchiveTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibility.archive)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  @override
  Stream<RenderList> watchFavoriteTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isFavoriteEqualTo(true)
        .not()
        .visibilityEqualTo(AssetVisibility.locked)
        .isTrashedEqualTo(false)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  @override
  Stream<RenderList> watchAlbumTimeline(
    Album album,
    GroupAssetsBy groupAssetByOption,
  ) {
    final query = album.assets
        .filter()
        .isTrashedEqualTo(false)
        .not()
        .visibilityEqualTo(AssetVisibility.locked);

    final withSortedOption = switch (album.assetOrder) {
      AssetOrder.asc => query.sortByFileCreatedAt(),
      AssetOrder.desc => query.sortByFileCreatedAtDesc(),
    };

    return _watchRenderList(withSortedOption, groupAssetByOption);
  }

  @override
  Stream<RenderList> watchTrashTimeline(String userId) {
    final query = db.assets
        .filter()
        .ownerIdEqualTo(fastHash(userId))
        .isTrashedEqualTo(true)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  @override
  Stream<RenderList> watchAllVideosTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibility.timeline)
        .typeEqualTo(AssetType.VIDEO)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  @override
  Stream<RenderList> watchHomeTimeline(
    String userId,
    GroupAssetsBy groupAssetByOption,
  ) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .stackPrimaryAssetIdIsNull()
        .visibilityEqualTo(AssetVisibility.timeline)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, groupAssetByOption);
  }

  @override
  Stream<RenderList> watchMultiUsersTimeline(
    List<String> userIds,
    GroupAssetsBy groupAssetByOption,
  ) {
    final isarUserIds = userIds.map(fastHash).toList();
    final query = db.assets
        .where()
        .anyOf(isarUserIds, (qb, id) => qb.ownerIdEqualToAnyChecksum(id))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibility.timeline)
        .stackPrimaryAssetIdIsNull()
        .sortByFileCreatedAtDesc();
    return _watchRenderList(query, groupAssetByOption);
  }

  @override
  Future<RenderList> getTimelineFromAssets(
    List<Asset> assets,
    GroupAssetsBy getGroupByOption,
  ) {
    return RenderList.fromAssets(assets, getGroupByOption);
  }

  @override
  Stream<RenderList> watchAssetSelectionTimeline(String userId) {
    final query = db.assets
        .where()
        .remoteIdIsNotNull()
        .filter()
        .ownerIdEqualTo(fastHash(userId))
        .visibilityEqualTo(AssetVisibility.timeline)
        .isTrashedEqualTo(false)
        .stackPrimaryAssetIdIsNull()
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  @override
  Stream<RenderList> watchLockedTimeline(
    String userId,
    GroupAssetsBy getGroupByOption,
  ) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .visibilityEqualTo(AssetVisibility.locked)
        .isTrashedEqualTo(false)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, getGroupByOption);
  }

  Stream<RenderList> _watchRenderList(
    QueryBuilder<Asset, Asset, QAfterSortBy> query,
    GroupAssetsBy groupAssetsBy,
  ) async* {
    yield await RenderList.fromQuery(query, groupAssetsBy);
    await for (final _ in query.watchLazy()) {
      yield await RenderList.fromQuery(query, groupAssetsBy);
    }
  }
}
