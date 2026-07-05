import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/member/search_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models_new/member/search_archive/data.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/member_search/controller.dart';

class MemberSearchChildController extends CommonListController {
  MemberSearchChildController(this.controller, this.searchType);

  final MemberSearchController controller;
  final MemberSearchType searchType;

  dynamic offset;

  int get _totalCount => controller.counts[searchType.index];

  set _totalCount(int value) => controller.counts[searchType.index] = value;

  @override
  void checkIsEnd(int length) {
    if (_totalCount != -1 && length >= _totalCount) {
      isEnd = true;
    }
  }

  @override
  List? getDataList(response) => switch (searchType) {
    MemberSearchType.archive => _getArchiveList(response as SearchArchiveData),
    MemberSearchType.dynamic => _getDynamicList(response as DynamicsDataModel),
  };

  List? _getArchiveList(SearchArchiveData data) {
    _totalCount = data.page?.count ?? 0;
    return data.list?.vlist;
  }

  List? _getDynamicList(DynamicsDataModel data) {
    offset = data.offset;
    if (data.hasMore == false) {
      isEnd = true;
    }
    _totalCount = data.total ?? 0;
    return data.items;
  }

  @override
  Future<void> onRefresh() {
    offset = null;
    return super.onRefresh();
  }

  @override
  Future<LoadingState> customGetData() {
    return switch (searchType) {
      MemberSearchType.archive => MemberHttp.searchArchive(
        mid: controller.mid,
        pn: page,
        keyword: controller.editingController.text,
        order: 'pubdate',
      ),
      MemberSearchType.dynamic => MemberHttp.dynSearch(
        mid: controller.mid,
        pn: page,
        offset: offset ?? '',
        keyword: controller.editingController.text,
      ),
    };
  }
}
