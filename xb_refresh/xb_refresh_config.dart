import 'package:flutter/material.dart';
export 'package:flutter/material.dart';

///before:继续下拉刷新
///ready:松开手刷新
///loading:正在刷新
///complete:完成刷新
enum RefreshOn { before, ready, loading, complete }

///before:继续上拉加载更多
///ready:松开手开始加载
///loading:正在加载
///hasMore:加载到了新数据
///noMore:没有新数据
enum LoadMoreOn { before, ready, loading, hasMore, noMore }

typedef XBRefreshBuilder = Widget Function(double height);
