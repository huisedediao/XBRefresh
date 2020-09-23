import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'xb_refresh_config.dart';

class Refresh extends StatefulWidget {
  final Widget child;
  final VoidCallback onBeginRefresh;
  final XBRefreshBuilder headerBeforeBuilder;
  final XBRefreshBuilder headerReadyBuilder;
  final XBRefreshBuilder headerLoadingBuilder;
  final XBRefreshBuilder headerCompleteBuilder;
  final bool needShowComplete;

  ///大于这个值可以刷新,也用于限制header的高度
  final double headerLoadingOffset;

  Refresh(
      {this.child,
      this.onBeginRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 60.0,
      this.needShowComplete = false,
      Key key})
      : super(key: key);

  @override
  RefreshState createState() => RefreshState();
}

class RefreshState extends State<Refresh> with SingleTickerProviderStateMixin {
  LoadMoreHeaderBuilderVM _headerBuilderVM;
  LoadMoreHeaderOffsetVM _headerOffsetVM;
  bool _isUserAction = false;
  double _lastOffset = 0;
  bool _isInProcess = false;
  bool _isCompleted = false;
  double _screenWidth = MediaQueryData.fromWindow(window).size.width;

  ///结束刷新
  endRefresh() {
    if (_headerBuilderVM.on == RefreshOn.loading) {
      _headerBuilderVM.on = RefreshOn.complete;
      Future.delayed(
          widget.needShowComplete ? Duration(seconds: 1) : Duration.zero, () {
        _headerBuilderVM.on = RefreshOn.before;
        _isCompleted = true;
        if (_headerOffsetVM.offset != 0) {
          _headerOffsetVM.offset = 0;
        }
        if (_lastOffset == 0 && _isUserAction == false) {
          _isInProcess = false;
          _isCompleted = false;
        }
      });
    }
  }

  receiveOffset(double offset) {
    bool upward = offset > _lastOffset;
    _lastOffset = offset;

    if (offset < 0) {
      ///已完成刷新但是还在流程里，说明没有等到非用户操作的offset = 0
      if (_isCompleted && _isInProcess) return;

      if (_isInProcess == false && _isUserAction) {
        ///进入流程
        _isInProcess = true;
      }

      if (_headerBuilderVM.on == RefreshOn.loading ||
          _headerBuilderVM.on == RefreshOn.complete) {
        return;
      }

      double fitOffset = 0 - offset;
      if (fitOffset <= 0) {
        return;
      }
      _headerOffsetVM.offset = fitOffset;

      if (upward) {
        if (_isUserAction) {
          _headerUserActionRun(fitOffset);
        } else {
          _headerBuilderVM.on = RefreshOn.before;
        }
      } else {
        if (_isUserAction) {
          _headerUserActionRun(fitOffset);
        }
      }
    } else if (offset == 0) {
      if (_headerBuilderVM.on == RefreshOn.before && _isUserAction == false) {
        _isInProcess = false;
        _isCompleted = false;
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _headerBuilderVM = LoadMoreHeaderBuilderVM();
    _headerOffsetVM = LoadMoreHeaderOffsetVM();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Listener(
            onPointerDown: (detail) {
              _isUserAction = true;
            },
            onPointerUp: (detail) {
              _isUserAction = false;

              if (_isCompleted && _isInProcess && _lastOffset == 0) {
                _isInProcess = false;
                _isCompleted = false;
              }

              if (_headerBuilderVM.on == RefreshOn.ready) {
                _headerBuilderVM.on = RefreshOn.loading;
                if (widget.onBeginRefresh != null) {
                  widget.onBeginRefresh();
                }
              }
            },
            child: widget.child),
        ChangeNotifierProvider(
          create: (ctx) {
            return _headerBuilderVM;
          },
          child: Consumer(builder: (ctx, LoadMoreHeaderBuilderVM vm, child) {
            Widget child;
            if (vm.on == RefreshOn.before) {
              child = _headerBeforeDispaly();
            } else if (vm.on == RefreshOn.ready) {
              child = _headerReadyDispaly();
            } else if (vm.on == RefreshOn.loading) {
              child = _headerLoadingDispaly();
            } else if (vm.on == RefreshOn.complete) {
              child = _headerCompleteDispaly();
            } else {
              child = Container();
            }
            return ChangeNotifierProvider(
              create: (ctx) {
                return _headerOffsetVM;
              },
              child: Consumer(
                builder: (ctx, LoadMoreHeaderOffsetVM offsetVM, reChild) {
                  double bottom = widget.headerLoadingOffset - offsetVM.offset;
                  if (bottom < 0) {
                    bottom = 0;
                  }
                  return Positioned(
                    top: -bottom,
                    child: Container(
//                        color: Colors.grey,
                      height: widget.headerLoadingOffset,
                      child: reChild,
                    ),
                  );
                },
                child: child,
              ),
            );
          }),
        ),
      ],
    );
  }

  _headerUserActionRun(double fitOffset) {
    if (fitOffset >= widget.headerLoadingOffset) {
      _headerBuilderVM.on = RefreshOn.ready;
    } else {
      _headerBuilderVM.on = RefreshOn.before;
    }
  }

  Widget _headerBeforeDispaly() {
    Widget child;
    if (widget.headerBeforeBuilder != null) {
      child = widget.headerBeforeBuilder(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(false);
    }

    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        width: _screenWidth,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerReadyDispaly() {
    Widget child;
    if (widget.headerReadyBuilder != null) {
      child = widget.headerReadyBuilder(widget.headerLoadingOffset);
    } else {
      child = _buildArrow(true);
    }
    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        width: _screenWidth,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerLoadingDispaly() {
    Widget child;
    if (widget.headerLoadingBuilder != null) {
      child = widget.headerLoadingBuilder(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        width: _screenWidth,
        height: widget.headerLoadingOffset,
        child: child);
  }

  Widget _headerCompleteDispaly() {
    Widget child;
    if (widget.headerCompleteBuilder != null) {
      child = widget.headerCompleteBuilder(widget.headerLoadingOffset);
    } else {
      child = _buildActivityIndicator();
    }
    return Container(
//        color: Colors.orange,
        alignment: Alignment.center,
        width: _screenWidth,
        height: widget.headerLoadingOffset,
        child: child);
  }

  _buildArrow(bool upward) {
    String title = upward ? "↑" : "↓";
    return Text(
      title,
      style: TextStyle(fontSize: 25),
    );
  }

  _buildActivityIndicator({bool animating = true}) {
    double width = 30;
    return Container(
      decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 15)]),
      width: width,
      height: width,
      alignment: Alignment.center,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.5),
          child: Container(
              color: Colors.white,
              height: width,
              width: width,
              child: CupertinoActivityIndicator(
                animating: animating,
              ))),
    );
  }
}

class LoadMoreHeaderOffsetVM extends ChangeNotifier {
  double _offset = 0;

  double get offset => _offset;

  set offset(double offset) {
    _offset = offset;
    notifyListeners();
  }
}

class LoadMoreHeaderBuilderVM extends ChangeNotifier {
  RefreshOn _on = RefreshOn.before;

  RefreshOn get on => _on;

  set on(RefreshOn on) {
    _on = on;
    notifyListeners();
  }
}
