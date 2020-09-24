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
  LoadMoreFooterPaddingVM _footerPaddingVM;
  LoadMoreChildPaddingVM _childPaddingVM;
  bool _isUserAction = false;
  double _lastOffset = 0;
  double _maxOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;

  ///hasMore是否有数据更新
  endLoadMore(bool hasMore) {
    if (_footerBuilderVM.on == LoadMoreOn.loading) {
      if (hasMore == true) {
        if (widget.needShowHasMoreFooter) {
          _footerBuilderVM.on = LoadMoreOn.hasMore;
          Future.delayed(Duration(seconds: 1), () {
            _afterHasMore();
          });
        } else {
          _afterHasMore();
        }
      } else {
        _footerBuilderVM.on = LoadMoreOn.noMore;
        Future.delayed(Duration(seconds: 1), () {
          _resetFooter();
          _childPaddingVM.bottom = 0;
          _isCompleted = true;
          _endProcessIfPossible();
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

      double top = widget.footerLoadingOffset - fitOffset;
      if (top < 0) {
        top = 0;
      }
      _footerPaddingVM.top = top;

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
    } else {
      _endProcessIfPossible();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _footerBuilderVM = LoadMoreFooterBuilderVM();
    _footerPaddingVM = LoadMoreFooterPaddingVM(widget.footerLoadingOffset);
    _childPaddingVM = LoadMoreChildPaddingVM();
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
                    return _footerPaddingVM;
                  },
                  child: Consumer(
                    builder: (ctx, LoadMoreFooterPaddingVM offsetVM, reChild) {
                      return Container(
//                        color: Colors.grey,
                        height: widget.footerLoadingOffset,
                        child: Padding(
                          padding: EdgeInsets.only(top: offsetVM.top),
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

              ///maxOffset为0说明是数据没有填满一屏幕的情况
              if (_lastOffset + widget.footerLoadingOffset <= _maxOffset ||
                  _maxOffset == 0) {
                _endProcessIfPossible();
              }

              if (_footerBuilderVM.on == LoadMoreOn.ready) {
                _footerBuilderVM.on = LoadMoreOn.loading;
                _childPaddingVM.bottom = widget.footerLoadingOffset;
                if (widget.onBeginLoadMore != null) {
                  widget.onBeginLoadMore();
                }
              }
            },
            child: ChangeNotifierProvider(
              create: (ctx) {
                return _childPaddingVM;
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

  _afterHasMore() {
    _childPaddingVM.bottom = 0;
    _resetFooter();
    _isCompleted = true;
    _endProcessIfPossible();
  }

  _endProcessIfPossible() {
    if (_isUserAction == false &&
        _lastOffset <= _maxOffset &&
        _isInProcess == true &&
        _isCompleted == true) {
      _isInProcess = false;
      _isCompleted = false;
    }
  }

  _resetFooter() {
    _footerBuilderVM.on = LoadMoreOn.before;
    if (_footerPaddingVM.top != widget.footerLoadingOffset) {
      _footerPaddingVM.top = widget.footerLoadingOffset;
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
    Widget child;
    if (widget.footerBeforeBuilder != null) {
      child = widget.footerBeforeBuilder(widget.footerLoadingOffset);
    } else {
      child = Text("上拉加载更多");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerReadyDispaly() {
    Widget child;
    if (widget.footerReadyBuilder != null) {
      child = widget.footerReadyBuilder(widget.footerLoadingOffset);
    } else {
      child = Text("松开手开始加载");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerLoadingDispaly() {
    Widget child;
    if (widget.footerLoadingBuilder != null) {
      child = widget.footerLoadingBuilder(widget.footerLoadingOffset);
    } else {
      child = Text("正在加载");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerHasMoreDispaly() {
    Widget child;
    if (widget.footerHasMoreBuilder != null) {
      child = widget.footerHasMoreBuilder(widget.footerLoadingOffset);
    } else {
      child = Text("加载完成");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }

  Widget _footerNoMoreDispaly() {
    Widget child;
    if (widget.footerNoMoreBuilder != null) {
      child = widget.footerNoMoreBuilder(widget.footerLoadingOffset);
    } else {
      child = Text("没有新数据啦~");
    }
    return Container(
        alignment: Alignment.center,
        height: widget.footerLoadingOffset,
        child: child);
  }
}

class LoadMoreFooterPaddingVM extends ChangeNotifier {
  double _top;

  double get top => _top;

  set top(double offset) {
    _top = offset;
    notifyListeners();
  }

  LoadMoreFooterPaddingVM(this._top);
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
