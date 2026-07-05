import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/member/search_type.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/member_search/child/controller.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class MemberSearchChildPage extends StatefulWidget {
  const MemberSearchChildPage({
    super.key,
    required this.controller,
    required this.searchType,
  });

  final MemberSearchChildController controller;
  final MemberSearchType searchType;

  @override
  State<MemberSearchChildPage> createState() => _MemberSearchChildPageState();
}

class _MemberSearchChildPageState extends State<MemberSearchChildPage>
    with AutomaticKeepAliveClientMixin, DynMixin, GridMixin {
  MemberSearchChildController get _controller => widget.controller;
  MemberSearchType get _searchType => widget.searchType;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = Obx(() => _buildBody(_controller.loadingState.value));
    return refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        controller: _controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: _searchType == MemberSearchType.archive ? 7 : 0,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: switch (_searchType) {
              MemberSearchType.archive => body,
              MemberSearchType.dynamic => buildPage(body),
            },
          ),
        ],
      ),
    );
  }

  Widget get _buildLoading {
    return switch (_searchType) {
      MemberSearchType.archive => gridSkeleton,
      MemberSearchType.dynamic => dynSkeleton,
    };
  }

  void _loadMoreOnLastItem(int index, int length) {
    if (index == length - 1) {
      _controller.onLoadMore();
    }
  }

  Widget _buildArchiveSliver(List response) => SliverGrid.builder(
    gridDelegate: gridDelegate,
    itemBuilder: (context, index) {
      _loadMoreOnLastItem(index, response.length);
      return VideoCardH(videoItem: response[index]);
    },
    itemCount: response.length,
  );

  Widget _buildDynamicPanel(dynamic item) =>
      DynamicPanel(item: item, maxWidth: maxWidth);

  Widget _buildDynamicSliver(List response) =>
      GlobalData().dynamicsWaterfallFlow
      ? SliverWaterfallFlow(
          gridDelegate: dynGridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, index) {
              _loadMoreOnLastItem(index, response.length);
              return _buildDynamicPanel(response[index]);
            },
            childCount: response.length,
          ),
        )
      : SliverList.builder(
          itemBuilder: (context, index) {
            _loadMoreOnLastItem(index, response.length);
            return _buildDynamicPanel(response[index]);
          },
          itemCount: response.length,
        );

  Widget _buildSuccessBody(List response) => switch (_searchType) {
    MemberSearchType.archive => _buildArchiveSliver(response),
    MemberSearchType.dynamic => _buildDynamicSliver(response),
  };

  Widget _buildBody(LoadingState<List?> loadingState) {
    return switch (loadingState) {
      Loading() => _buildLoading,
      Success(:var response) =>
        response?.isNotEmpty == true
            ? Builder(
                builder: (context) => _buildSuccessBody(response!),
              )
            : HttpError(onReload: _controller.onReload),
      Error(:var errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
