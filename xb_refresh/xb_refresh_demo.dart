import 'package:flutter/material.dart';
import 'xb_refresh.dart';

class XBRefreshDemo extends StatefulWidget {
  @override
  _XBRefreshDemoState createState() => _XBRefreshDemoState();
}

class _XBRefreshDemoState extends State<XBRefreshDemo> {
  ScrollController _controller = ScrollController();
  GlobalKey<XBRefreshState> _refreshKey = GlobalKey();

  int _itemCount = 10;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller.addListener(() {
      _refreshKey.currentState.receiveOffset(
          _controller.offset, _controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("xb refresh demo"),
        ),
        body: XBRefresh(
            key: _refreshKey,
            needLoadMore: true,
            needRefresh: true,
//            needShowHasMoreFooter: true,

            ///开始加载更多的回调
            onBeginLoadMore: () {
              Future.delayed(Duration(seconds: 2), () {
                bool hasMore = false;
                if (_itemCount < 20) {
                  hasMore = true;
                  setState(() {
                    _itemCount += 5;
                  });
                }

                ///结束加载更多，传是否有新数据
                _refreshKey.currentState.endLoadMore(hasMore);
              });
            },
            onBeginRefresh: () {
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  _itemCount = 10;
                });
                _refreshKey.currentState.endRefresh();
              });
            },
            child: CustomScrollView(
              controller: _controller,
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: <Widget>[
                SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, index) {
                  return Cell("$index", () {});
                }, childCount: _itemCount))
              ],
            )));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Cell extends StatelessWidget {
  static final height = 44.0;
  final String title;
  final VoidCallback onPressed;

  Cell(this.title, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        color: Colors.black38,
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Text(title, style: TextStyle(color: Colors.white)))),
            Container(
              height: 1,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }
}
