import 'package:PiliPlus/http/live.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/live_search_type.dart';
import 'package:PiliPlus/models_new/live/live_search/data.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/live_search/controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:get/get.dart';

class LiveSearchChildController
    extends CommonListController<LiveSearchData, dynamic> {
  LiveSearchChildController(this.controller, this.searchType);

  final LiveSearchController controller;
  final LiveSearchType searchType;
  final AccountService accountService = Get.find<AccountService>();

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
    LiveSearchType.room => _getRoomList(response),
    LiveSearchType.user => _getUserList(response),
  };

  List? _getRoomList(LiveSearchData response) {
    _totalCount = response.room?.totalRoom ?? 0;
    return response.room?.list;
  }

  List? _getUserList(LiveSearchData response) {
    _totalCount = response.user?.totalUser ?? 0;
    return response.user?.list;
  }

  @override
  Future<LoadingState<LiveSearchData>> customGetData() {
    return LiveHttp.liveSearch(
      isLogin: accountService.isLogin.value,
      page: page,
      keyword: controller.editingController.text,
      type: searchType,
    );
  }
}
