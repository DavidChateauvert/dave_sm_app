import 'package:flutter/material.dart';

class ChooseGroups extends StatefulWidget {
  final Widget child;
  const ChooseGroups({super.key, required this.child});

  void expand() {
    (ChooseGroupsState? state) {
      if (state != null) {
        state.expand();
      }
    };
  }

  @override
  State<ChooseGroups> createState() => ChooseGroupsState();
}

class ChooseGroupsState extends State<ChooseGroups> {
  final sheet = GlobalKey();
  final controller = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    controller.addListener(onChanged);
  }

  void onChanged() {
    final currentSize = controller.size;
    if (currentSize <= 0.05) {
      collaspe();
    }
  }

  void collaspe() => animateSheet(getSheet.snapSizes!.first);
  void anchor() => animateSheet(getSheet.snapSizes!.first);
  void expand() => animateSheet(getSheet.maxChildSize);
  void hide() => animateSheet(getSheet.minChildSize);

  void animateSheet(double size) {
    controller.animateTo(size,
        duration: const Duration(microseconds: 50), curve: Curves.easeInOut);
  }

  DraggableScrollableSheet get getSheet =>
      (sheet.currentWidget as DraggableScrollableSheet);

  SliverToBoxAdapter topButtonIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              child: Center(
                child: Wrap(
                  children: [
                    Container(
                      width: 100.0,
                      margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (builder, constraints) {
        return DraggableScrollableSheet(
          key: sheet,
          initialChildSize: 0.5,
          maxChildSize: 0.95,
          minChildSize: 0,
          expand: true,
          snap: true,
          snapSizes: [
            60 / constraints.maxHeight,
            0.5,
          ],
          builder: (BuildContext context, ScrollController scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary,
                    blurRadius: 10.0,
                    spreadRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22.0),
                  topRight: Radius.circular(22.0),
                ),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  topButtonIndicator(),
                  SliverToBoxAdapter(
                    child: widget.child,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
