import 'xb_refresh_config.dart';
import 'package:provider/provider.dart';

class LoadMore extends StatefulWidget {
  final Widget child;
  final VoidCallback onBeginLoadMore;
  final XBRefreshBuilder footerBeforeBuilder;
  final XBRefreshBuilder footerReadyBuilder;
  final XBRefreshBuilder footerLoadingBuilder;
  final XBRefreshBuilder footerNoMoreBuilder;
  final XBRefreshBuilder footerHasMoreBuilder;
  final bool needShowHasMoreFooter;

  ///大于这个值可以加载更多,也用于限制footer的高度
  final double footerLoadingOffset;

  LoadMore(
      {this.child,
      this.onBeginLoadMore,
      this.footerBeforeBuilder,
      this.footerReadyBuilder,
      this.footerNoMoreBuilder,
      this.footerHasMoreBuilder,
      this.footerLoadingBuilder,
      this.needShowHasMoreFooter = false,
      this.footerLoadingOffset = 50.0,
      Key key})
      : super(key: key);

  @override
  LoadMoreState createState() => LoadMoreState();
}

class LoadMoreState extends State<LoadMore>
    with SingleTickerProviderStateMixin {
  LoadMoreFooterBuilderVM _footerBuilderVM;
  LoadMoreFooterOffsetVM _footerOffsetVM;
  LoadMoreChildPaddingVM _paddingVM;
  bool _isUserAction = false;
  double _lastOffset = 0;
  double _maxOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;

  ///hasMore是否有数据更新
  endLoadMore(bool hasMore) {
    print(hasMore);
    if (_footerBuilderVM.on == LoadMoreOn.loading) {
      if (hasMore) {
        _footerBuilderVM.on = LoadMoreOn.hasMore;
        Future.delayed(
            widget.needShowHasMoreFooter ? Duration(seconds: 1) : Duration.zero,
            () {
          _paddingVM.bottom = 0;
          _resetFooter();
          _isCompleted = true;
          if (_lastOffset == _maxOffset && _isUserAction == false) {
            _isInProcess = false;
            _isCompleted = false;
          }
        });
      } else {
        _footerBuilderVM.on = LoadMoreOn.noMore;
        Future.delayed(Duration(seconds: 1), () {
          _resetFooter();
          _paddingVM.bottom = 0;
          _isCompleted = true;
          if (_lastOffset == _maxOffset && _isUserAction == false) {
            _isInProcess = false;
            _isCompleted = false;
          }
        });
      }
    }
  }

  receiveOffset(double offset, double maxOffset) {
    _maxOffset = maxOffset;
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (offset > _maxOffset) {
      ///已完成刷新但是还在流程里，说明没有等到非用户操作的offset = 0
      if (_isCompleted && _isInProcess) return;

      if (_isInProcess == false && _isUserAction) {
        ///进入流程
        _isInProcess = true;
      }

      if (_footerBuilderVM.on == LoadMoreOn.loading ||
          _footerBuilderVM.on == LoadMoreOn.hasMore ||
          _footerBuilderVM.on == LoadMoreOn.noMore) {
        return;
      }
      double fitOffset = offset - maxOffset;
      if (fitOffset <= 0) {
        return;
      }
      _footerOffsetVM.offset = fitOffset;

      if (upward) {
        if (_isUserAction) {
          _footerUserActionRun(fitOffset);
        } else {
          _footerBuilderVM.on = LoadMoreOn.before;
        }
      } else {
        if (_isUserAction) {
          _footerUserActionRun(fitOffset);
        }
      }
    } else if (offset <= maxOffset) {
      if (_footerBuilderVM.on == LoadMoreOn.before && _isUserAction == false) {
        _isInProcess = false;
        _isCompleted = false;
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _footerBuilderVM = LoadMoreFooterBuilderVM();
    _footerOffsetVM = LoadMoreFooterOffsetVM();
    _paddingVM = LoadMoreChildPaddingVM();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(child: Container()),
            ChangeNotifierProvider(
              create: (ctx) {
                return _footerBuilderVM;
              },
              child:
                  Consumer(builder: (ctx, LoadMoreFooterBuilderVM vm, child) {
                Widget child;
                if (vm.on == LoadMoreOn.before) {
                  child = _footerBeforeDispaly();
                } else if (vm.on == LoadMoreOn.ready) {
                  child = _footerReadyDispaly();
                } else if (vm.on == LoadMoreOn.loading) {
                  child = _footerLoadingDispaly();
                } else if (vm.on == LoadMoreOn.hasMore) {
                  child = _footerHasMoreDispaly();
                } else if (vm.on == LoadMoreOn.noMore) {
                  child = _footerNoMoreDispaly();
                } else {
                  child = Container();
                }
                return ChangeNotifierProvider(
                  create: (ctx) {
                    return _footerOffsetVM;
                  },
                  child: Consumer(
                    builder: (ctx, LoadMoreFooterOffsetVM offsetVM, reChild) {
                      double top = widget.footerLoadingOffset - offsetVM.offset;
                      if (top < 0) {
                        top = 0;
                      }
                      return Container(
//                        color: Colors.grey,
                        height: widget.footerLoadingOffset,
                        child: Padding(
                          padding: EdgeInsets.only(top: top),
                          child: reChild,
                        ),
                      );
                    },
                    child: child,
                  ),
                );
              }),
            )
          ],
        ),
        Listener(
            onPointerDown: (detail) {
              _isUserAction = true;
            },
            onPointerUp: (detail) {
              _isUserAction = false;

              if (_isCompleted && _isInProcess && _lastOffset <= _maxOffset) {
                _isInProcess = false;
                _isCompleted = false;
              }

              if (_footerBuilderVM.on == LoadMoreOn.ready) {
                _footerBuilderVM.on = LoadMoreOn.loading;
                _paddingVM.bottom = widget.footerLoadingOffset;
                if (widget.onBeginLoadMore != null) {
                  widget.onBeginLoadMore();
                }
              }
            },
            child: ChangeNotifierProvider(
              create: (ctx) {
                return _paddingVM;
              },
              child: Consumer(
                builder: (ctx, LoadMoreChildPaddingVM vm, child) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: vm.bottom),
                    child: child,
                  );
                },
                child: widget.child,
              ),
            )),
      ],
    );
  }

  _resetFooter() {
    _footerBuilderVM.on = LoadMoreOn.before;
    if (_footerOffsetVM.offset != 0) {
      _footerOffsetVM.offset = 0;
    }
  }

  _footerUserActionRun(double fitOffset) {
    if (fitOffset >= widget.footerLoadingOffset) {
      _footerBuilderVM.on = LoadMoreOn.ready;
    } else {
      _footerBuilderVM.on = LoadMoreOn.before;
    }
  }

  Widget _footerBeforeDispaly() {
    if (widget.footerBeforeBuilder != null)
      return widget.footerBeforeBuilder(widget.footerLoadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: Text("上拉加载更多"));
  }

  Widget _footerReadyDispaly() {
    if (widget.footerReadyBuilder != null)
      return widget.footerReadyBuilder(widget.footerLoadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: Text("松开手开始加载"));
  }

  Widget _footerLoadingDispaly() {
    if (widget.footerLoadingBuilder != null)
      return widget.footerLoadingBuilder(widget.footerLoadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: Text("正在加载"));
  }

  Widget _footerHasMoreDispaly() {
    if (widget.footerHasMoreBuilder != null)
      return widget.footerHasMoreBuilder(widget.footerLoadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: Text("加载完成"));
  }

  Widget _footerNoMoreDispaly() {
    if (widget.footerNoMoreBuilder != null)
      return widget.footerNoMoreBuilder(widget.footerLoadingOffset);
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: Text("没有新数据啦~"));
  }
}

class LoadMoreFooterOffsetVM extends ChangeNotifier {
  double _offset = 0;

  double get offset => _offset;

  set offset(double offset) {
    _offset = offset;
    notifyListeners();
  }
}

class LoadMoreFooterBuilderVM extends ChangeNotifier {
  LoadMoreOn _on = LoadMoreOn.before;

  LoadMoreOn get on => _on;

  set on(LoadMoreOn on) {
    _on = on;
    notifyListeners();
  }
}

class LoadMoreChildPaddingVM extends ChangeNotifier {
  double _bottom = 0;

  double get bottom => _bottom;

  set bottom(double bottom) {
    _bottom = bottom;
    notifyListeners();
  }
}
