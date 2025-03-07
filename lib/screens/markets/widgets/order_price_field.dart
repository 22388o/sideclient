import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sideswap/common/helpers.dart';
import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/models/markets_provider.dart';
import 'package:sideswap/models/request_order_provider.dart';
import 'package:sideswap/protobuf/sideswap.pb.dart';
import 'package:sideswap/screens/markets/widgets/order_price_text_field.dart';
import 'package:sideswap/screens/markets/widgets/order_tracking_slider.dart';
import 'package:sideswap/screens/markets/widgets/switch_buton.dart';

class OrderPriceField extends StatelessWidget {
  const OrderPriceField({
    Key? key,
    required this.controller,
    this.asset,
    this.icon,
    required this.description,
    this.focusNode,
    this.dollarConversion = '',
    this.onEditingComplete,
    this.tracking = false,
    this.onToggleTracking,
    required this.sliderValue,
    required this.onSliderChanged,
    this.trackingPrice = '',
    this.displaySlider = false,
  }) : super(key: key);

  final TextEditingController controller;
  final Asset? asset;
  final Image? icon;
  final String description;
  final FocusNode? focusNode;
  final String dollarConversion;
  final void Function()? onEditingComplete;
  final bool tracking;
  final void Function(bool)? onToggleTracking;
  final double sliderValue;
  final void Function(double)? onSliderChanged;
  final String trackingPrice;
  final bool displaySlider;

  @override
  Widget build(BuildContext context) {
    final isToken =
        context.read(requestOrderProvider).isAssetToken(asset?.assetId);
    final indexPrice =
        context.read(marketsProvider).getIndexPriceStr(asset?.assetId ?? '');
    var minPercent = -1;
    var maxPercent = 1;
    if (!tracking && (!isToken && indexPrice.isNotEmpty)) {
      minPercent = -3;
      maxPercent = 3;
    }

    return SizedBox(
      height: isToken ? 129.h : 188.h,
      child: Column(
        children: [
          SizedBox(
            height: 32.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer(
                  builder: (context, watch, child) {
                    var indexPrice = watch(marketsProvider)
                        .getIndexPriceStr(asset?.assetId ?? '');
                    if (displaySlider && onSliderChanged != null) {
                      Future.microtask(() => onSliderChanged!(sliderValue));
                    }

                    if (indexPrice.isEmpty) {
                      return Container();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Index price:'.tr(),
                          style: GoogleFonts.roboto(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00C5FF),
                          ),
                        ),
                        Text(
                          '${replaceCharacterOnPosition(input: indexPrice)} ${asset?.ticker}',
                          style: GoogleFonts.roboto(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SwitchButton(
                  width: 142.w,
                  height: 35.h,
                  borderRadius: 8.r,
                  borderWidth: 2.r,
                  activeText: 'Tracking'.tr(),
                  inactiveText: 'Limit'.tr(),
                  value: tracking,
                  onToggle: onToggleTracking,
                ),
              ],
            ),
          ),
          if (displaySlider) ...[
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: OrderTrackingSlider(
                value: sliderValue,
                onChanged: onSliderChanged,
                minPercent: minPercent,
                maxPercent: maxPercent,
                icon: icon,
                asset: asset,
                price: controller.text,
                dollarConversion: dollarConversion,
              ),
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: OrderPriceTextField(
                icon: icon,
                asset: asset,
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
