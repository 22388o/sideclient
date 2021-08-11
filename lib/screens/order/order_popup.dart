import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/common/widgets/custom_app_bar.dart';
import 'package:sideswap/common/widgets/custom_big_button.dart';
import 'package:sideswap/common/widgets/side_swap_progress_bar.dart';
import 'package:sideswap/common/widgets/side_swap_scaffold.dart';
import 'package:sideswap/models/wallet.dart';
import 'package:sideswap/screens/order/widgets/order_details.dart';
import 'package:sideswap/screens/markets/widgets/autosign.dart';
import 'package:sideswap/screens/markets/widgets/order_table.dart';

class OrderPopup extends StatefulWidget {
  const OrderPopup({Key? key}) : super(key: key);

  @override
  _OrderPopupState createState() => _OrderPopupState();
}

class _OrderPopupState extends State<OrderPopup> {
  int seconds = 60;
  int percent = 100;
  Timer? _percentTimer;
  bool autoSign = true;
  bool enabled = true;
  bool percentEnabled = false;
  bool orderTypeValue = false;

  @override
  void initState() {
    super.initState();
    final orderDetailsData = context.read(walletProvider).orderDetailsData;
    autoSign = orderDetailsData.autoSign;

    // if (orderDetailsData.orderType == OrderType.execute) {
    //   _percentTimer = Timer.periodic(Duration(seconds: 1), onTimer);
    // }
  }

  void onTimer(Timer timer) {
    seconds--;
    if (seconds == 0) {
      _percentTimer?.cancel();
      context.read(walletProvider).setRegistered();
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      percent = seconds * 100 ~/ 60;
    });
  }

  @override
  void dispose() {
    _percentTimer?.cancel();
    super.dispose();
  }

  void onClose() {
    context.read(walletProvider).setSubmitDecision(
          autosign: autoSign,
          accept: false,
        );
    context.read(walletProvider).goBack();
  }

  @override
  Widget build(BuildContext context) {
    return SideSwapScaffold(
      sideSwapBackground: false,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF064363),
      appBar: CustomAppBar(
        onPressed: () {
          onClose();
        },
      ),
      body: Center(
        child: Consumer(
          builder: (context, watch, child) {
            final orderDetailsData = watch(walletProvider).orderDetailsData;
            OrderDetailsDataType? orderType =
                orderDetailsData.orderType ?? OrderDetailsDataType.submit;
            final dataAvailable = orderDetailsData.isDataAvailable();

            var orderDescription = '';
            switch (orderType) {
              case OrderDetailsDataType.submit:
                orderDescription = 'Submit an order'.tr();
                break;
              case OrderDetailsDataType.quote:
                orderDescription = 'Submit response'.tr();
                break;
              case OrderDetailsDataType.sign:
                orderDescription = 'Accept swap'.tr();
                break;
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (orderType == OrderDetailsDataType.sign) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 67.h),
                      child: Container(
                        height: 109.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8.w)),
                          color: const Color(0xFF014767),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 24.h),
                                child: Container(
                                  width: 26.w,
                                  height: 26.w,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00C5FF),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/success.svg',
                                      width: 11.w,
                                      height: 11.w,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 16.h),
                                child: Text(
                                  'Your order has been matched'.tr(),
                                  style: GoogleFonts.roboto(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.only(top: 32.h),
                    child: Text(
                      orderDescription,
                      style: GoogleFonts.roboto(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
                        color: const Color(0xFF043857),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: OrderTable(
                          orderDetailsData: orderDetailsData,
                          enabled: dataAvailable,
                        ),
                      ),
                    ),
                  ),
                  if (orderType == OrderDetailsDataType.quote &&
                      percentEnabled) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: SideSwapProgressBar(
                        percent: percent,
                        text: '${seconds}s left',
                      ),
                    ),
                  ],
                  if (orderType == OrderDetailsDataType.submit) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: AutoSign(
                        value: autoSign,
                        onToggle: (value) {
                          setState(() {
                            autoSign = value;
                          });
                        },
                      ),
                    ),
                    const OrderTypeTracking(),
                  ],
                  const Spacer(),
                  CustomBigButton(
                    width: double.maxFinite,
                    height: 54.h,
                    enabled: dataAvailable && enabled,
                    backgroundColor: const Color(0xFF00C5FF),
                    onPressed: () async {
                      final auth =
                          await context.read(walletProvider).isAuthenticated();
                      if (auth) {
                        setState(() {
                          enabled = false;
                        });
                        switch (orderType) {
                          case OrderDetailsDataType.submit:
                          case OrderDetailsDataType.quote:
                          case OrderDetailsDataType.sign:
                            context.read(walletProvider).setSubmitDecision(
                                  autosign: autoSign,
                                  accept: true,
                                  private: false,
                                );
                            break;
                        }
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!enabled) ...[
                          Padding(
                            padding: EdgeInsets.only(right: 200.w),
                            child: SpinKitCircle(
                              size: 32.w,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                        Text(
                          enabled
                              ? orderType == OrderDetailsDataType.submit ||
                                      orderType == OrderDetailsDataType.sign
                                  ? 'SUBMIT'.tr()
                                  : 'SUBMIT RESPONSE'.tr()
                              : orderType == OrderDetailsDataType.sign
                                  ? 'Broadcasting'.tr()
                                  : 'Awaiting acceptance'.tr(),
                          style: GoogleFonts.roboto(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
                    child: CustomBigButton(
                      width: double.maxFinite,
                      height: 54.h,
                      text: 'Cancel'.tr(),
                      textColor: const Color(0xFF00C5FF),
                      backgroundColor: Colors.transparent,
                      enabled: enabled,
                      onPressed: onClose,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class OrderTypeTracking extends StatelessWidget {
  const OrderTypeTracking({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Container(
        height: 51.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8.w)),
          color: const Color(0xFF014767),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order type:'.tr(),
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              Consumer(
                builder: (context, watch, child) {
                  final indexPrice =
                      watch(walletProvider).orderDetailsData.isTracking;
                  return Text(
                    indexPrice ? 'Price tracking'.tr() : 'Limit order'.tr(),
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
