import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sideswap/common/widgets/custom_big_button.dart';
import 'package:sideswap/models/payment_requests_provider.dart';
import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/models/wallet.dart';
import 'package:sideswap/screens/pay/widgets/friend_widget.dart';
import 'package:sideswap/screens/markets/confirm_request_payment.dart';

class RequestPaymentItem extends StatelessWidget {
  const RequestPaymentItem(
      {Key? key, required this.request, required this.onCancelPressed})
      : super(key: key);

  final PaymentRequest request;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    var height = 158.h;
    var header = 'Sended'.tr();
    final _dateFormat = DateFormat('dd MMMM yyyy');

    if (request.type == PaymentRequestType.received) {
      height = 214.h;
      header = 'Received'.tr();
    }

    return Container(
      width: double.maxFinite,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
        color: const Color(0xFF1D6389),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(left: 16.w, right: 16.w, top: 18.h, bottom: 22.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$header - ${_dateFormat.format(request.dateTime)}',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF709EBA),
              ),
            ),
            FriendWidget(
              friend: request.friend,
              showTrailingIcon: false,
              contentPadding: EdgeInsets.zero,
              customDescription: Row(
                children: [
                  Text(
                    request.amount,
                    style: GoogleFonts.roboto(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: context
                            .read(walletProvider)
                            .assetImagesSmall[request.assetId] ??
                        Container(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: Text(
                      context
                              .read(walletProvider)
                              .assets[request.assetId]
                              ?.ticker ??
                          '',
                      style: GoogleFonts.roboto(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Text(
                request.message ?? '',
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
            if (request.type == PaymentRequestType.received) ...[
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomBigButton(
                      width: 151.w,
                      height: 36.h,
                      text: 'CANCEL'.tr(),
                      onPressed: onCancelPressed,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                          color: const Color(0xFF00C5FF), width: 2.r),
                    ),
                    CustomBigButton(
                      width: 151.w,
                      height: 36.h,
                      text: 'SEND'.tr(),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute(
                            builder: (context) => ConfirmRequestPayment(
                              request: request,
                            ),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFF00C5FF),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
