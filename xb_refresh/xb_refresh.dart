import 'xb_refresh_config.dart';
import 'load_more.dart';
import 'refresh.dart';

class XBRefresh extends StatefulWidget {
  final Widget child;
  final VoidCallback onBeginRefresh;
  final VoidCallback onBeginLoadMore;
  final XBRefreshBuilder headerBeforeBuilder;
  final XBRefreshBuilder headerReadyBuilder;
  final XBRefreshBuilder headerLoadingBuilder;
  final XBRefreshBuilder headerCompleteBuilder;
  final XBRefreshBuilder footerBeforeBuilder;
  final XBRefreshBuilder footerReadyBuilder;
  final XBRefreshBuilder footerLoadingBuilder;
  final XBRefreshBuilder footerNoMoreBuilder;
  final XBRefreshBuilder footerHasMoreBuilder;
  final bool needShowHasMoreFooter;
  final bool needShowComplete;
  final double headerLoadingOffset;
  final double footerLoadingOffset;
  final bool needRefresh;
  final bool needLoadMore;

  XBRefresh(
      {@required this.child,
      this.onBeginRefresh,
      this.headerBeforeBuilder,
      this.headerReadyBuilder,
      this.headerLoadingBuilder,
      this.headerCompleteBuilder,
      this.headerLoadingOffset = 50.0,
      this.needShowComplete = false,
      this.onBeginLoadMore,
      this.footerBeforeBuilder,
      this.footerReadyBuilder,
      this.footerNoMoreBuilder,
      this.footerHasMoreBuilder,
      this.footerLoadingBuilder,
      this.needShowHasMoreFooter = false,
      this.footerLoadingOffset = 50.0,
      this.needRefresh = true,
      this.needLoadMore = true,
      Key key})
      : super(key: key);

  @override
  XBRefreshState createState() => XBRefreshState();
}

class XBRefreshState extends State<XBRefresh> {
  GlobalKey<LoadMoreState> _loadMoreKey = GlobalKey();
  GlobalKey<RefreshState> _refreshKey = GlobalKey();

  endRefresh() {
    if (_refreshKey.currentState != null) {
      _refreshKey.currentState.endRefresh();
    }
  }

  endLoadMore(bool hasMore) {
    if (_loadMoreKey.currentState != null) {
      _loadMoreKey.currentState.endLoadMore(hasMore);
    }
  }

  receiveOffset(double offset, double maxOffset) {
    if (_refreshKey.currentState != null) {
      _refreshKey.currentState.receiveOffset(offset);
    }
    if (_loadMoreKey.currentState != null) {
      _loadMoreKey.currentState.receiveOffset(offset, maxOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needRefresh && widget.needLoadMore) {
      return _buildRefresh(_buildLoadMore(widget.child));
    } else if (widget.needLoadMore) {
      return _buildLoadMore(widget.child);
    } else if (widget.needRefresh) {
      return _buildRefresh(widget.child);
    } else {
      return widget.child;
    }
  }

  _buildRefresh(Widget child) {
    return Refresh(
      key: _refreshKey,
      onBeginRefresh: widget.onBeginRefresh,
      headerBeforeBuilder: widget.headerBeforeBuilder,
      headerReadyBuilder: widget.headerReadyBuilder,
      headerLoadingBuilder: widget.headerLoadingBuilder,
      headerCompleteBuilder: widget.headerCompleteBuilder,
      needShowComplete: widget.needShowComplete,
      headerLoadingOffset: widget.headerLoadingOffset,
      child: child,
    );
  }

  _buildLoadMore(Widget child) {
    return LoadMore(
      key: _loadMoreKey,
      onBeginLoadMore: widget.onBeginLoadMore,
      footerBeforeBuilder: widget.footerBeforeBuilder,
      footerReadyBuilder: widget.footerReadyBuilder,
      footerLoadingBuilder: widget.footerLoadingBuilder,
      footerNoMoreBuilder: widget.footerNoMoreBuilder,
      footerHasMoreBuilder: widget.footerHasMoreBuilder,
      needShowHasMoreFooter: widget.needShowHasMoreFooter,
      footerLoadingOffset: widget.footerLoadingOffset,
      child: child,
    );
  }
}
