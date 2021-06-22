import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:sideswap/common/helpers.dart';
import 'package:sideswap/common/screen_utils.dart';
import 'package:sideswap/common/utils/custom_logger.dart';
import 'package:sideswap/common/utils/decimal_text_input_formatter.dart';
import 'package:sideswap/models/swap_provider.dart';
import 'package:sideswap/models/wallet.dart';
import 'package:sideswap/protobuf/sideswap.pb.dart';
import 'package:sideswap/screens/swap/fee_suggestions.dart';

class TickerAmountTextField extends StatefulWidget {
  TickerAmountTextField({
    Key? key,
    this.onDropdownChanged,
    required this.dropdownValue,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.availableAssets = const <String>[],
    this.readOnly = false,
    this.dropdownReadOnly = false,
    this.showError = false,
    this.hintText = '',
    this.showHintText = false,
    this.feeRates = const <FeeRate>[],
    this.onFeeRateChanged,
  }) : super(key: key);

  final void Function(String)? onDropdownChanged;
  final String dropdownValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final List<String> availableAssets;
  final bool readOnly;
  final bool dropdownReadOnly;
  final bool showError;
  final String hintText;
  final bool showHintText;
  final List<FeeRate> feeRates;
  final void Function(FeeRate)? onFeeRateChanged;

  @override
  _TickerAmountTextFieldState createState() => _TickerAmountTextFieldState();
}

class _TickerAmountTextFieldState extends State<TickerAmountTextField> {
  final _textFieldStyle = GoogleFonts.roboto(
    fontSize: 26.sp,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  final _dropdownTextStyle = GoogleFonts.roboto(
    fontSize: 22.sp,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  FocusNode _textfieldFocusNode = FocusNode();
  bool _visibleHintText = false;
  FeeRate? _feeRate;

  @override
  void initState() {
    super.initState();
    _visibleHintText = widget.showHintText;

    _feeRate = widget.feeRates.isNotEmpty ? widget.feeRates.first : null;

    _textfieldFocusNode = widget.focusNode ?? FocusNode();
    _textfieldFocusNode.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_textfieldFocusNode.hasFocus && !widget.readOnly) {
          _visibleHintText = false;
        } else {
          _visibleHintText = widget.showHintText;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant TickerAmountTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feeRates != oldWidget.feeRates && widget.feeRates.isNotEmpty) {
      setState(() {
        logger.d('OLD FEE: $_feeRate');
        final blocks = _feeRate?.blocks ?? 2;
        _feeRate = widget.feeRates.firstWhere((e) => e.blocks == blocks);
        logger.d('NEW FEE: $_feeRate');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderDecoration = BoxDecoration(
      shape: BoxShape.rectangle,
      border: Border(
        bottom: BorderSide(
          color: (widget.showError && !widget.readOnly)
              ? Color(0xFFFF7878)
              : (_textfieldFocusNode.hasFocus && !widget.readOnly)
                  ? Color(0xFF00C5FF)
                  : Color(0xFF2B6F95),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
    );

    return Container(
      height: 43.h,
      decoration: widget.feeRates.isNotEmpty ? null : borderDecoration,
      child: Column(
        children: [
          Container(
            height: 42.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration:
                      widget.feeRates.isNotEmpty ? borderDecoration : null,
                  child: Row(
                    children: [
                      Consumer(
                        builder: (context, watch, child) {
                          final _icon = context
                              .read(walletProvider)
                              .assetImagesSmall[widget.dropdownValue];

                          return Container(
                            width: 32.w,
                            height: 32.w,
                            child: Center(child: _icon),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            icon: widget.dropdownReadOnly
                                ? Container()
                                : Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                            dropdownColor: Color(0xFF2B6F95),
                            style: _dropdownTextStyle,
                            onChanged: widget.dropdownReadOnly
                                ? null
                                : (value) {
                                    if (widget.onDropdownChanged == null ||
                                        value == null) {
                                      return;
                                    }
                                    widget.onDropdownChanged!(value);
                                  },
                            disabledHint: widget.dropdownReadOnly
                                ? Container(
                                    width: 68.w,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8.w,
                                        ),
                                        Text(
                                          context
                                                  .read(walletProvider)
                                                  .getAssetById(
                                                      widget.dropdownValue)
                                                  ?.ticker ??
                                              '',
                                          style: _dropdownTextStyle,
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                            value: widget.dropdownValue,
                            items: widget.availableAssets.map((value) {
                              final _asset =
                                  context.read(walletProvider).assets[value];
                              final image = context
                                  .read(walletProvider)
                                  .assetImagesSmall[_asset?.assetId];

                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    if (image != null) ...[
                                      image,
                                    ],
                                    Container(
                                      width: 8.w,
                                    ),
                                    if (_asset?.ticker != null) ...[
                                      Text(
                                        _asset?.ticker ?? '',
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (context) {
                              return widget.availableAssets.map((value) {
                                final _asset =
                                    context.read(walletProvider).assets[value];
                                return Container(
                                  width: 68.w,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8.w,
                                      ),
                                      if (_asset?.ticker != null) ...[
                                        Text(
                                          _asset?.ticker ?? '',
                                          style: _dropdownTextStyle,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, watch, child) {
                      if (context.read(swapProvider).swapType() ==
                              SwapType.pegIn &&
                          widget.readOnly) {
                        _visibleHintText = false;
                      }

                      if (widget.feeRates.isNotEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(left: 18.w),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true)
                                    .push<void>(
                                  MaterialPageRoute(
                                    builder: (context) => FeeRates(
                                      feeRates: widget.feeRates,
                                      onPressed: (value) {
                                        setState(() {
                                          _feeRate = value;
                                          if (widget.onFeeRateChanged != null) {
                                            widget.onFeeRateChanged!(value);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 42.h,
                                decoration: borderDecoration,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 225.w,
                                    height: 42.h,
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 6.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              getFeeRate(feeRate: _feeRate),
                                              overflow: TextOverflow.clip,
                                              maxLines: 1,
                                              style: GoogleFonts.roboto(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 3.h),
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 16.w,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final assetPrecision = context
                              .read(walletProvider)
                              .assets[widget.dropdownValue]
                              ?.precision ??
                          kDefaultPrecision;

                      return Container(
                        height: 42.h,
                        child: TextField(
                          autofocus: false,
                          readOnly: widget.readOnly,
                          controller: widget.controller,
                          focusNode: _textfieldFocusNode,
                          textAlign: TextAlign.end,
                          style: _textFieldStyle,
                          cursorColor: Colors.white,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            CommaTextInputFormatter(),
                            if (assetPrecision == 0) ...[
                              FilteringTextInputFormatter.deny(
                                  RegExp('[\\-|,\\ .]')),
                            ] else ...[
                              FilteringTextInputFormatter.deny(
                                  RegExp('[\\-|,\\ ]')),
                            ],
                            DecimalTextInputFormatter(
                                decimalRange: assetPrecision),
                          ],
                          onChanged: widget.onChanged,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: _visibleHintText ? widget.hintText : '',
                            hintStyle: _textFieldStyle,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }
}
