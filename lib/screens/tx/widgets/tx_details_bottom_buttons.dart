import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sideswap/common/helpers.dart';
import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/common/widgets/custom_big_button.dart';
import 'package:sideswap/models/wallet.dart';
import 'package:sideswap/screens/tx/share_external_explorer_dialog.dart';

class TxDetailsBottomButtons extends StatefulWidget {
  const TxDetailsBottomButtons({
    Key? key,
    required this.id,
    required this.isLiquid,
    this.enabled = true,
    this.blindType = BlindType.both,
  }) : super(key: key);

  final String id;
  final bool isLiquid;
  final BlindType blindType;
  final bool enabled;

  @override
  _TxDetailsBottomButtonsState createState() => _TxDetailsBottomButtonsState();
}

class _TxDetailsBottomButtonsState extends State<TxDetailsBottomButtons> {
  StreamSubscription? openExplorerSubscription;
  StreamSubscription? shareExplorerSubscription;

  Future<void> _openUrl(String txid, bool isLiquid, bool unblinded) async {
    await openExplorerSubscription?.cancel();
    openExplorerSubscription =
        context.read(walletProvider).explorerUrlSubject.listen((value) async {
      await openExplorerSubscription?.cancel();
      await openUrl(value);
    });

    context.read(walletProvider).openTxUrl(txid, isLiquid, unblinded);
  }

  Future<void> _shareAddress(String txid, bool isLiquid, bool unblinded) async {
    await shareExplorerSubscription?.cancel();
    shareExplorerSubscription =
        context.read(walletProvider).explorerUrlSubject.listen((value) async {
      await shareExplorerSubscription?.cancel();
      await shareAddress(value);
    });

    context.read(walletProvider).openTxUrl(txid, isLiquid, unblinded);
  }

  @override
  void dispose() {
    openExplorerSubscription?.cancel();
    shareExplorerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomBigButton(
          height: 54.h,
          width: 251.w,
          enabled: widget.enabled,
          onPressed: () async {
            await showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return ShareExternalExplorerDialog(
                  shareIconType: ShareIconType.link,
                  blindType: widget.blindType,
                  onBlindedPressed: () async {
                    await _openUrl(widget.id, widget.isLiquid, false);
                  },
                  onUnblindedPressed: () async {
                    await _openUrl(widget.id, widget.isLiquid, true);
                  },
                );
              },
            );
          },
          child: Padding(
            padding: EdgeInsets.only(left: 16.w, right: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View in external explorer'.tr(),
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
                Transform(
                  transform: Matrix4.rotationY(-2 * pi / 2),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/back_arrow.svg',
                    width: 8.16.w,
                    height: 14.73.w,
                    color: const Color(0xFF00C5FF),
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomBigButton(
          height: 54.h,
          width: 60.w,
          enabled: widget.enabled,
          onPressed: () async {
            await showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return ShareExternalExplorerDialog(
                  shareIconType: ShareIconType.share,
                  blindType: widget.blindType,
                  onBlindedPressed: () async {
                    await _shareAddress(widget.id, widget.isLiquid, false);
                  },
                  onUnblindedPressed: () async {
                    await _shareAddress(widget.id, widget.isLiquid, true);
                  },
                );
              },
            );
          },
          child: SvgPicture.asset(
            'assets/share2.svg',
            width: 22.w,
            height: 26.w,
            color: const Color(0xFF00C5FF),
          ),
        ),
      ],
    );
  }
}
