import 'dart:async';

import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/search/suggest.dart';
import 'package:PiliPlus/models_new/search/search_rcmd/data.dart';
import 'package:PiliPlus/models_new/search/search_trending/data.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:stream_transform/stream_transform.dart';

mixin DebounceStreamMixin<T> {
  Duration duration = const Duration(milliseconds: 200);
  StreamController<T>? ctr;
  StreamSubscription<T>? sub;
  void onValueChanged(T value);

  void subInit() {
    ctr = StreamController<T>();
    sub = ctr!.stream.debounce(duration, trailing: true).listen(onValueChanged);
  }

  void subDispose() {
    sub?.cancel();
    ctr?.close();
    sub = null;
    ctr = null;
  }
}

abstract class DebounceStreamState<T extends StatefulWidget, S> extends State<T>
    with DebounceStreamMixin<S> {
  @override
  void dispose() {
    subDispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    subInit();
  }
}

class SSearchController extends GetxController
    with DebounceStreamMixin<String> {
  SSearchController(this.tag);
  final String tag;

  final searchFocusNode = FocusNode();
  final controller = TextEditingController();

  String? hintText;

  int initIndex = 0;

  // uid
  final RxBool showUidBtn = false.obs;

  // history
  final RxBool recordSearchHistory = Pref.recordSearchHistory.obs;
  late final RxList<String> historyList;

  // suggestion
  final bool searchSuggestion = Pref.searchSuggestion;
  late final RxList<SearchSuggestItem> searchSuggestList;
  int _suggestRequestId = 0;

  // trending
  final bool enableTrending = Pref.enableTrending;
  late final Rx<LoadingState<SearchTrendingData>> trendingState;

  // rcmd
  final bool enableSearchRcmd = Pref.enableSearchRcmd;
  late final Rx<LoadingState<SearchRcmdData>> recommendData;
  String get currentKeyword => _keyword;

  @override
  void onInit() {
    super.onInit();
    final params = Get.parameters;
    hintText = params['hintText'];
    final text = params['text'];
    if (text != null) {
      controller.text = text;
    }

    historyList = _normalizeHistory(
      List<String>.from(
        GStorage.historyWord.get('cacheList') ?? [],
      ),
    ).obs;
    validateUid();

    if (searchSuggestion) {
      subInit();
      searchSuggestList = <SearchSuggestItem>[].obs;
    }

    if (enableTrending) {
      trendingState = LoadingState<SearchTrendingData>.loading().obs;
      queryTrendingList();
    }

    if (enableSearchRcmd) {
      recommendData = LoadingState<SearchRcmdData>.loading().obs;
      queryRecommendList();
    }
  }

  String get _keyword => controller.text.trim();

  List<String> _normalizeHistory(List<String> list) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final item in list) {
      final keyword = item.trim();
      if (keyword.isNotEmpty && seen.add(keyword)) {
        normalized.add(keyword);
      }
    }
    return normalized;
  }

  void _setSearchText(String value) {
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
  }

  void _clearSuggestList() {
    _suggestRequestId++;
    if (searchSuggestion && searchSuggestList.isNotEmpty) {
      searchSuggestList.clear();
    }
  }

  void _persistHistory() {
    GStorage.historyWord.put('cacheList', historyList.toList(growable: false));
  }

  void _insertHistory(String keyword) {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return;
    }
    historyList
      ..remove(normalizedKeyword)
      ..insert(0, normalizedKeyword);
    _persistHistory();
  }

  void replaceHistory(List<String> list) {
    historyList.value = _normalizeHistory(list);
    _persistHistory();
  }

  void toggleRecordSearchHistory() {
    final enable = !recordSearchHistory.value;
    recordSearchHistory.value = enable;
    GStorage.setting.put(SettingBoxKey.recordSearchHistory, enable);
  }

  void validateUid() {
    showUidBtn.value = IdUtils.digitOnlyRegExp.hasMatch(_keyword);
  }

  void onChange(String value) {
    validateUid();
    if (searchSuggestion) {
      final keyword = value.trim();
      if (keyword.isEmpty) {
        _clearSuggestList();
      } else {
        ctr?.add(keyword);
      }
    }
  }

  void onClear() {
    if (controller.value.text != '') {
      controller.clear();
      _clearSuggestList();
      searchFocusNode.requestFocus();
      showUidBtn.value = false;
    } else {
      Get.back();
    }
  }

  // 搜索
  Future<void> submit() async {
    var keyword = _keyword;
    if (keyword.isEmpty) {
      if (hintText.isNullOrEmpty) {
        return;
      }
      keyword = hintText!.trim();
      if (keyword.isEmpty) {
        return;
      }
      _setSearchText(keyword);
      validateUid();
    } else if (keyword != controller.text) {
      _setSearchText(keyword);
    }

    if (recordSearchHistory.value) {
      _insertHistory(keyword);
    }

    searchFocusNode.unfocus();
    await Get.toNamed(
      '/searchResult',
      parameters: {
        'tag': tag,
        'keyword': keyword,
      },
      arguments: {
        'initIndex': initIndex,
        'fromSearch': true,
      },
    );
    searchFocusNode.requestFocus();
    if (Utils.isDesktop) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      });
    }
  }

  // 获取热搜关键词
  Future<void> queryTrendingList() async {
    trendingState.value = await SearchHttp.searchTrending(limit: 10);
  }

  Future<void> queryRecommendList() async {
    recommendData.value = await SearchHttp.searchRecommend();
  }

  void onClickKeyword(String keyword) {
    _setSearchText(keyword.trim());
    validateUid();
    _clearSuggestList();
    submit();
  }

  @override
  Future<void> onValueChanged(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      _clearSuggestList();
      return;
    }
    final requestId = ++_suggestRequestId;
    final res = await SearchHttp.searchSuggest(term: keyword);
    final isLatest = requestId == _suggestRequestId && keyword == _keyword;
    if (!isLatest) {
      return;
    }
    if (res['status'] == true) {
      SearchSuggestModel data = res['data'];
      if (data.tag?.isNotEmpty == true) {
        searchSuggestList.value = data.tag!;
      } else {
        searchSuggestList.clear();
      }
    } else {
      searchSuggestList.clear();
    }
  }

  void onLongSelect(String word) {
    historyList.remove(word);
    _persistHistory();
  }

  void onClearHistory() {
    showConfirmDialog(
      context: Get.context!,
      title: '确定清空搜索历史？',
      onConfirm: () {
        historyList.clear();
        GStorage.historyWord.delete('cacheList');
      },
    );
  }

  @override
  void onClose() {
    subDispose();
    searchFocusNode.dispose();
    controller.dispose();
    super.onClose();
  }
}
