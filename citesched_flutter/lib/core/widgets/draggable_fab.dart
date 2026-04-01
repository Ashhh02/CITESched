import 'package:flutter/material.dart';

/// A wrapper widget that makes its child draggable within a Stack.
/// On mobile, dragging it to the far-right edge tucks it away and leaves
/// a small side toggle so it can slide back in without covering content.
class DraggableFab extends StatefulWidget {
  final Widget child;

  const DraggableFab({
    super.key,
    required this.child,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  final GlobalKey _childKey = GlobalKey();
  Offset? _offset;
  Size _childSize = const Size(168, 56);
  bool _isHiddenToRight = false;

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialOffset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  void _ensureInitialOffset() {
    if (_offset != null) return;
    final size = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    _offset = Offset(
      size.width - _childSize.width - 20,
      size.height - _childSize.height - safeBottom - 24,
    );
  }

  void _measureChild() {
    final renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final measuredSize = renderObject.size;
    if (!mounted || measuredSize == _childSize) return;

    final oldSize = _childSize;
    final oldOffset = _offset;
    setState(() {
      _childSize = measuredSize;
      if (oldOffset != null) {
        _offset = _clampOffset(oldOffset, previousSize: oldSize);
      }
    });
  }

  Offset _clampOffset(Offset desired, {Size? previousSize}) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final safeTop = media.padding.top + 8;
    final safeBottom = media.padding.bottom + 8;
    final fabSize = previousSize ?? _childSize;

    final minX = 8.0;
    final maxX = screen.width - fabSize.width - 8;
    final minY = safeTop;
    final maxY = screen.height - fabSize.height - safeBottom;

    return Offset(
      desired.dx.clamp(minX, maxX),
      desired.dy.clamp(minY, maxY),
    );
  }

  void _hideToRight() {
    final screen = MediaQuery.of(context).size;
    const visibleTabWidth = 22.0;
    setState(() {
      _isHiddenToRight = true;
      _offset = Offset(
        screen.width - visibleTabWidth,
        _clampOffset(_offset!).dy,
      );
    });
  }

  void _showFromRight() {
    final screen = MediaQuery.of(context).size;
    setState(() {
      _isHiddenToRight = false;
      _offset = Offset(
        screen.width - _childSize.width - 12,
        _clampOffset(_offset!).dy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialOffset();
    final mobile = _isMobile(context);
    final currentOffset = _clampOffset(_offset!);

    if (currentOffset != _offset) {
      _offset = currentOffset;
    }

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: _offset!.dx,
            top: _offset!.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_isHiddenToRight) return;
                setState(() {
                  _offset = _clampOffset(
                    Offset(
                      _offset!.dx + details.delta.dx,
                      _offset!.dy + details.delta.dy,
                    ),
                  );
                });
              },
              onPanEnd: (_) {
                if (!mobile || _isHiddenToRight) return;
                final hideThreshold =
                    MediaQuery.of(context).size.width - (_childSize.width * 0.35);
                if (_offset!.dx >= hideThreshold) {
                  _hideToRight();
                }
              },
              child: Opacity(
                opacity: _isHiddenToRight ? 0 : 1,
                child: IgnorePointer(
                  ignoring: _isHiddenToRight,
                  child: KeyedSubtree(
                    key: _childKey,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          if (mobile && _isHiddenToRight)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              right: 0,
              top: _offset!.dy,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showFromRight,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: Container(
                    width: 42,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F003B).withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
