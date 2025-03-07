import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum WalletMainNavigationItem {
  home,
  homeAssetReceive,
  accounts,
  assetSelect,
  assetDetails,
  assetReceive,
  transactions,
  markets,
  swap,
}

class WalletMainArguments {
  int currentIndex;
  WalletMainNavigationItem navigationItem;

  WalletMainArguments({
    required this.currentIndex,
    required this.navigationItem,
  });

  WalletMainArguments fromIndex(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return copyWith(
            currentIndex: currentIndex,
            navigationItem: WalletMainNavigationItem.home);
      case 1:
        return copyWith(
            currentIndex: currentIndex,
            navigationItem: WalletMainNavigationItem.accounts);
      case 2:
        return copyWith(
            currentIndex: currentIndex,
            navigationItem: WalletMainNavigationItem.markets);
      case 3:
        return copyWith(
            currentIndex: currentIndex,
            navigationItem: WalletMainNavigationItem.swap);
    }

    return copyWith(
        currentIndex: currentIndex,
        navigationItem: WalletMainNavigationItem.home);
  }

  WalletMainArguments copyWith({
    int? currentIndex,
    WalletMainNavigationItem? navigationItem,
  }) {
    return WalletMainArguments(
      currentIndex: currentIndex ?? this.currentIndex,
      navigationItem: navigationItem ?? this.navigationItem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WalletMainArguments &&
        other.currentIndex == currentIndex &&
        other.navigationItem == navigationItem;
  }

  @override
  int get hashCode => currentIndex.hashCode ^ navigationItem.hashCode;

  @override
  String toString() =>
      'WalletMainArguments(currentIndex: $currentIndex, navigationItem: $navigationItem)';
}

final uiStateArgsProvider =
    ChangeNotifierProvider<UiStateArgsChangeNotifierProvider>((ref) {
  return UiStateArgsChangeNotifierProvider();
});

class UiStateArgsChangeNotifierProvider extends ChangeNotifier {
  WalletMainArguments _walletMainArguments;
  WalletMainArguments _lastWalletMainArguments = WalletMainArguments(
      currentIndex: 0, navigationItem: WalletMainNavigationItem.home);

  WalletMainArguments get walletMainArguments => _walletMainArguments;
  set walletMainArguments(WalletMainArguments walletMainArguments) {
    _lastWalletMainArguments = _walletMainArguments;
    _walletMainArguments = walletMainArguments;
    notifyListeners();
  }

  WalletMainArguments get lastWalletMainArguments => _lastWalletMainArguments;

  factory UiStateArgsChangeNotifierProvider() {
    return _uiStateArgs;
  }

  UiStateArgsChangeNotifierProvider._internal()
      : _walletMainArguments = WalletMainArguments(
            currentIndex: 0, navigationItem: WalletMainNavigationItem.home);

  static final UiStateArgsChangeNotifierProvider _uiStateArgs =
      UiStateArgsChangeNotifierProvider._internal();
}
