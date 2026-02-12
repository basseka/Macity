import 'package:flutter/material.dart';

class AdBannerMarquee extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const AdBannerMarquee({
    super.key,
    this.text = " votre pub ici !!!   ",
    this.backgroundColor = const Color(0xFF4A1259),
    this.textColor = Colors.white,
    this.height = 40,
  });

  @override
  State<AdBannerMarquee> createState() => _AdBannerMarqueeState();
}

class _AdBannerMarqueeState extends State<AdBannerMarquee>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _animationController.value * maxScroll,
        );
      }
    });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Repeat the text enough times to ensure continuous scrolling
    final repeatedText = widget.text * 20;

    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            repeatedText,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
