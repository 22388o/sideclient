import 'dart:math' as math show sin, pi;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/common/widgets/side_swap_scaffold.dart';
import 'package:sideswap/models/initialize_app_provider.dart';

class PreLaunchPage extends StatefulWidget {
  const PreLaunchPage({
    Key? key,
  }) : super(key: key);

  @override
  _PreLaunchPageState createState() => _PreLaunchPageState();
}

class _PreLaunchPageState extends State<PreLaunchPage>
    with SingleTickerProviderStateMixin {
  final _counter = 5;
  final _color = const Color(0xFF00C5FF);
  final List<double> delays = [.0, .25, .5, .75, 1.0];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}))
      ..repeat();

    // initialize app
    context.read(initializeAppProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SideSwapScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 180.h),
                child: SizedBox(
                  width: 110.w,
                  height: 108.h,
                  child: SvgPicture.asset('assets/logo.svg'),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30.h),
              child: Text(
                'Wallet loading...',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 239.h),
                child: SizedBox(
                  width: 66.w,
                  height: 10.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ...List<Widget>.generate(
                        _counter,
                        (i) => FadeTransition(
                          opacity:
                              DelayTween(begin: 0.2, end: 1.0, delay: delays[i])
                                  .animate(_controller),
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  DelayTween({double? begin, double? end, required this.delay})
      : super(begin: begin, end: end);

  final double delay;

  @override
  double lerp(double t) =>
      super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}
