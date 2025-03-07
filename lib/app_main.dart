import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:secure_application/secure_application.dart';

import 'package:sideswap/common/helpers.dart';
import 'package:sideswap/common/theme.dart';
import 'package:sideswap/common/utils/custom_logger.dart';
import 'package:sideswap/models/config_provider.dart';
import 'package:sideswap/models/notifications_service.dart';
import 'package:sideswap/models/pin_protection_provider.dart';
import 'package:sideswap/models/request_order_provider.dart';
import 'package:sideswap/models/universal_link_provider.dart';
import 'package:sideswap/models/wallet.dart';
import 'package:sideswap/prelaunch_page.dart';
import 'package:sideswap/screens/background/preload_background_painter.dart';
import 'package:sideswap/screens/balances.dart';
import 'package:sideswap/screens/home/wallet_locked.dart';
import 'package:sideswap/screens/onboarding/associate_phone_welcome.dart';
import 'package:sideswap/screens/onboarding/confirm_phone.dart';
import 'package:sideswap/screens/onboarding/confirm_phone_success.dart';
import 'package:sideswap/screens/onboarding/first_launch.dart';
import 'package:sideswap/screens/onboarding/import_avatar.dart';
import 'package:sideswap/screens/onboarding/import_avatar_success.dart';
import 'package:sideswap/screens/onboarding/import_contacts.dart';
import 'package:sideswap/screens/onboarding/import_contacts_success.dart';
import 'package:sideswap/screens/onboarding/import_wallet_error.dart';
import 'package:sideswap/screens/onboarding/import_wallet_success.dart';
import 'package:sideswap/screens/onboarding/license.dart';
import 'package:sideswap/screens/onboarding/pin_setup.dart';
import 'package:sideswap/screens/onboarding/pin_welcome.dart';
import 'package:sideswap/screens/onboarding/wallet_backup.dart';
import 'package:sideswap/screens/onboarding/wallet_backup_check.dart';
import 'package:sideswap/screens/onboarding/wallet_backup_check_failed.dart';
import 'package:sideswap/screens/onboarding/wallet_backup_check_succeed.dart';
import 'package:sideswap/screens/onboarding/wallet_backup_new_prompt.dart';
import 'package:sideswap/screens/onboarding/wallet_import.dart';
import 'package:sideswap/screens/onboarding/widgets/import_wallet_biometric_prompt.dart';
import 'package:sideswap/screens/onboarding/widgets/new_wallet_biometric_prompt.dart';
import 'package:sideswap/screens/onboarding/widgets/new_wallet_pin_welcome.dart';
import 'package:sideswap/screens/onboarding/widgets/pin_success.dart';
import 'package:sideswap/screens/order/order_popup.dart';
import 'package:sideswap/screens/order/order_success.dart';
import 'package:sideswap/screens/pay/payment_amount_page.dart';
import 'package:sideswap/screens/pay/payment_page.dart';
import 'package:sideswap/screens/pay/payment_send_popup.dart';
import 'package:sideswap/screens/pin/pin_protection.dart';
import 'package:sideswap/screens/register.dart';
import 'package:sideswap/screens/markets/create_order_view.dart';
import 'package:sideswap/screens/markets/order_entry.dart';
import 'package:sideswap/screens/markets/create_order_success.dart';
import 'package:sideswap/screens/settings/settings.dart';
import 'package:sideswap/screens/settings/settings_about_us.dart';
import 'package:sideswap/screens/settings/settings_network.dart';
import 'package:sideswap/screens/settings/settings_security.dart';
import 'package:sideswap/screens/settings/settings_user_details.dart';
import 'package:sideswap/screens/settings/settings_view_backup.dart';
import 'package:sideswap/screens/swap/peg_in_address.dart';
import 'package:sideswap/screens/tx/tx_details_popup.dart';
import 'package:sideswap/screens/wallet_main/wallet_main.dart';

final initProvider = FutureProvider<bool>((ref) async {
  LicenseRegistry.addLicense(() async* {
    var license = await rootBundle
        .loadString('assets/licenses/libwally-core-license.txt');
    yield LicenseEntryWithLineBreaks([kPackageLibwally], license);
    license = await rootBundle.loadString('assets/licenses/gdk-license.txt');
    yield LicenseEntryWithLineBreaks([kPackageGdk], license);
  });

  final config = ref.read(configProvider);
  return await config.init();
});

class AppMain extends StatelessWidget {
  const AppMain({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PreloadBackgroundPainter(),
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        //preloaderColor: Colors.transparent,
        child: const ProviderScope(child: MyApp()),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    notificationService.init(context);
    context.read(universalLinkProvider).handleIncomingLinks();
    context.read(universalLinkProvider).handleInitialUri();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 667),
      builder: () => MaterialApp(
        title: 'SideSwap',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: SecureApplication(
          nativeRemoveDelay: 100,
          onNeedUnlock: (secureApplicationController) async {
            secureApplicationController?.unlock();
            return SecureApplicationAuthenticationStatus.NONE;
          },
          child: _RootWidget(),
        ),
      ),
    );
  }
}

class MyPopupPage<T> extends Page<T> {
  const MyPopupPage({required this.child});
  final Widget child;
  @override
  Route<T> createRoute(BuildContext context) {
    return _MyPopupPageRoute<T>(page: this);
  }
}

class _MyPopupPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _MyPopupPageRoute({
    required MyPopupPage<T> page,
  }) : super(settings: page);

  MyPopupPage<T> get _page => settings as MyPopupPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;
}

class _RootWidget extends StatefulWidget {
  @override
  __RootWidgetState createState() => __RootWidgetState();
}

class __RootWidgetState extends State<_RootWidget> {
  List<Page<dynamic>> pages(BuildContext context, Status status) {
    switch (status) {
      case Status.loading:
      case Status.walletLoading:
        return [
          const MaterialPage<Widget>(child: PreLaunchPage()),
        ];
      case Status.reviewLicenseCreateWallet:
        return [
          const MyPopupPage<Widget>(
            child: LicenseTerms(
              nextStep: LicenseNextStep.createWallet,
            ),
          ),
        ];
      case Status.reviewLicenseImportWallet:
        return [
          const MyPopupPage<Widget>(
            child: LicenseTerms(
              nextStep: LicenseNextStep.importWallet,
            ),
          ),
        ];
      case Status.noWallet:
        return [
          const MaterialPage<Widget>(child: FirstLaunch()),
        ];
      case Status.selectEnv:
        return [
          const MaterialPage<Widget>(child: FirstLaunch()),
          const MyPopupPage<Widget>(child: SelectEnv()),
        ];
      case Status.lockedWalet:
        return [
          const MaterialPage<Widget>(child: WalletLocked()),
        ];
      case Status.importWallet:
        return [
          const MaterialPage<Widget>(child: FirstLaunch()),
          const MaterialPage<Widget>(child: WalletImport()),
        ];
      case Status.importWalletBiometricPrompt:
        return [
          const MaterialPage<Widget>(child: ImportWalletBiometricPrompt()),
        ];
      case Status.importWalletSuccess:
        return [
          const MyPopupPage<Widget>(child: ImportWalletSuccess()),
        ];
      case Status.importWalletError:
        return [
          const MyPopupPage<Widget>(child: ImportWalletError()),
        ];
      case Status.newWalletBackupPrompt:
        return [
          const MaterialPage<Widget>(child: WalletBackupNewPrompt()),
        ];
      case Status.newWalletBackupView:
        return [
          const MaterialPage<Widget>(child: WalletBackupNewPrompt()),
          const MyPopupPage<Widget>(child: WalletBackup()),
        ];
      case Status.newWalletBackupCheck:
        return [
          const MaterialPage<Widget>(child: WalletBackupNewPrompt()),
          const MyPopupPage<Widget>(child: WalletBackup()),
          const MyPopupPage<Widget>(child: WalletBackupCheck()),
        ];
      case Status.newWalletBackupCheckFailed:
        return [
          const MaterialPage<Widget>(child: WalletBackupNewPrompt()),
          const MyPopupPage<Widget>(child: WalletBackupCheckFailed()),
        ];
      case Status.newWalletBackupCheckSucceed:
        return [
          const MaterialPage<Widget>(child: WalletBackupNewPrompt()),
          const MyPopupPage<Widget>(child: WalletBackupCheckSucceed()),
        ];
      case Status.newWalletBiometricPrompt:
        return [
          const MaterialPage<Widget>(child: NewWalletBiometricPrompt()),
        ];
      case Status.importAvatar:
        return [
          MaterialPage<Widget>(child: ImportAvatar()),
        ];
      case Status.importAvatarSuccess:
        return [
          MaterialPage<Widget>(child: ImportAvatar()),
          const MyPopupPage<Widget>(child: ImportAvatarSuccess()),
        ];
      case Status.associatePhoneWelcome:
        return [
          const MaterialPage<Widget>(child: AssociatePhoneWelcome()),
        ];
      case Status.confirmPhone:
        return [
          const MyPopupPage<Widget>(child: ConfirmPhone()),
        ];
      case Status.confirmPhoneSuccess:
        return [
          MyPopupPage<Widget>(child: ConfirmPhoneSuccess()),
        ];
      case Status.importContacts:
        return [
          const MaterialPage<Widget>(child: ImportContacts()),
        ];
      case Status.importContactsSuccess:
        return [
          const MyPopupPage<Widget>(child: ImportContactsSuccess()),
        ];
      // WalletMain has it's own navigation system because of
      // MainBottomNavigationBar
      // Use uiStateArgsProvider for changing page
      case Status.registered:
      case Status.assetsSelect:
      case Status.assetDetails:
      case Status.assetReceive:
      case Status.assetReceiveFromWalletMain:
        return [
          const MaterialPage<Widget>(child: WalletMain()),
        ];
      case Status.txDetails:
        return [
          const MyPopupPage<Widget>(child: TxDetailsPopup()),
        ];
      case Status.txEditMemo:
        return [
          const MaterialPage<Widget>(child: WalletTxMemo()),
        ];

      case Status.swapWaitPegTx:
        return [
          const MaterialPage<Widget>(child: WalletMain()),
          const MaterialPage<Widget>(child: PegInAddress()),
        ];
      case Status.swapTxDetails:
        return [
          const MyPopupPage<Widget>(child: TxDetailsPopup()),
        ];
      case Status.settingsPage:
        return [
          const MaterialPage<Widget>(child: Settings()),
        ];
      case Status.settingsBackup:
        return [
          const MaterialPage<Widget>(child: Settings()),
          const MaterialPage<Widget>(
            child: SecureGate(
              child: SettingsViewBackup(),
            ),
          ),
        ];
      case Status.settingsUserDetails:
        return [
          const MaterialPage<Widget>(child: Settings()),
          const MaterialPage<Widget>(child: SettingsUserDetails()),
        ];
      case Status.settingsAboutUs:
        return [
          const MaterialPage<Widget>(child: Settings()),
          const MaterialPage<Widget>(child: SettingsAboutUs()),
        ];
      case Status.settingsNetwork:
        return [
          const MaterialPage<Widget>(child: Settings()),
          const MaterialPage<Widget>(child: SettingsNetwork()),
        ];
      case Status.settingsSecurity:
        return [
          const MaterialPage<Widget>(child: Settings()),
          const MaterialPage<Widget>(child: SettingsSecurity()),
        ];
      case Status.paymentPage:
        return [
          const MaterialPage<Widget>(child: PaymentPage()),
        ];
      case Status.paymentAmountPage:
        return [
          const MaterialPage<Widget>(child: PaymentAmountPage()),
        ];
      case Status.paymentSend:
        return [
          const MyPopupPage<Widget>(child: PaymentSendPopup()),
        ];
      case Status.orderPopup:
        final orderId = context.read(walletProvider).orderDetailsData.orderId;
        return [
          const MaterialPage<Widget>(child: WalletMain()),
          MaterialPage<Widget>(child: OrderPopup(key: Key(orderId))),
        ];
      case Status.orderSuccess:
        return [
          const MyPopupPage<Widget>(child: OrderSuccess()),
        ];
      case Status.orderResponseSuccess:
        return [
          const MyPopupPage<Widget>(
            child: OrderSuccess(
              isResponse: true,
            ),
          ),
        ];
      case Status.newWalletPinWelcome:
        return [
          const MaterialPage<Widget>(child: NewWalletPinWelcome()),
        ];

      case Status.pinWelcome:
        return [
          const MaterialPage<Widget>(child: PinWelcome()),
        ];
      case Status.pinSetup:
        return [
          const MaterialPage<Widget>(child: PinSetup()),
        ];
      case Status.pinSuccess:
        return [
          const MyPopupPage<Widget>(child: PinSuccess()),
        ];
      case Status.createOrderEntry:
        return [
          const MaterialPage<Widget>(child: OrderEntry()),
        ];
      case Status.createOrder:
        return [
          const MaterialPage<Widget>(child: CreateOrderView()),
        ];
      case Status.createOrderSuccess:
        return [
          const MyPopupPage<Widget>(child: CreateOrderSuccess()),
        ];
      case Status.orderRequestView:
        return [
          const MaterialPage<Widget>(child: WalletMain()),
          MaterialPage<Widget>(
              child: CreateOrderView(
            requestOrder:
                context.read(requestOrderProvider).currentRequestOrderView,
          )),
        ];
    }
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    context.read(walletProvider).navigatorKey = _navigatorKey;
    context.read(pinProtectionProvider).onPinBlockadeCallback = onPinBlockade;
  }

  Future<bool> onPinBlockade() async {
    final ret = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const PinProtection();
      },
    );
    context.read(pinProtectionProvider).deinit();
    return ret ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WillPopScope(
          onWillPop: () async {
            // https://github.com/flutter/flutter/issues/66349
            final ret = await _navigatorKey.currentState?.maybePop() ?? false;
            return !ret;
          },
          child: Consumer(
            builder: (context, watch, child) {
              final status = watch(walletProvider).status;
              return Navigator(
                key: _navigatorKey,
                pages: pages(context, status),
                onPopPage: (route, dynamic result) {
                  logger.d('on pop page');
                  if (!route.didPop(result)) {
                    return false;
                  }
                  return true;
                },
              );
            },
          ),
        ),
        Consumer(
          builder: (context, watch, child) {
            final initProviderValue = watch(initProvider);
            return initProviderValue.map(data: (_) {
              final env = watch(configProvider).env;
              return Visibility(
                visible: env != 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      child: Text(
                        envName(env),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, loading: (_) {
              logger.d('loading');
              return Container();
            }, error: (_) {
              logger.e('Env error :${_.error.toString()}');
              return Container();
            });
          },
        ),
      ],
    );
  }
}
