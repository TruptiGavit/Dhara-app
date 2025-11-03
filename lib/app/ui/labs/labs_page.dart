import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/labs/cubit_states.dart';
import 'package:dharak_flutter/app/ui/labs/labs_controller.dart';
import 'package:dharak_flutter/app/ui/sections/auth/constants.dart';

import 'package:dharak_flutter/app/ui/shared/common/scrollbar/fix/index.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';

import '../../providers/google/signin-button/index.dart';

class LabsPage extends StatefulWidget {
  final String title;
  const LabsPage({super.key, this.title = 'LabsPage'});
  @override
  LabsPageState createState() => LabsPageState();
}

class LabsPageState extends State<LabsPage> {
  var mLogger = Logger();

  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;
  LabsController mBloc = Modular.get<LabsController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    mBloc.initSetup();
  }

  @override
  Widget build(BuildContext context) {
    // var contactBox = ContactBox();
    // LabsController mBloc = BlocProvider.of<LabsController>(context);

    // var ds = Provider.of<LabsController>(context);
    // var ds = context.watch<LabsController>((v)=> v.stream);
    // mLogger.d("initState ${mBloc.check()}");
    mBloc.check();

    // BlocProvider.of<LabsController>(context);

    var width = MediaQuery.of(context).size.width;

    mLogger.d(
      "LabsPageState: ${width} ${MediaQuery.of(context).devicePixelRatio}",
    );
    prepareTheme(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ScrollbarFix(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TdResGaps.v_16,
                // LabsCheckWidget(
                //   child: SizedBox.shrink(),
                // ),
                // Icon(
                //   CommonIcons.arrow_down_small,
                //   color: Colors.black,
                // ),
                Text("Contacts .."),
                TdResGaps.v_16,

                Text("Pages"),
                TdResGaps.v_16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Dashboard'),
                    onPressed: () {
                      var path = UiConstants.Routes.getRoutePath(
                        UiConstants.Routes.wordDefine,
                      );

                      Modular.to.navigate(path);
                    },
                  ),
                ),
                TdResGaps.v_16,

                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     child: const Text('Word Verse'),
                //     onPressed: () {
                //       //  var path = UiConstants.Routes.getRoutePath(UiConstants.Routes.wordDefine);

                //       // Modular.to.navigate(path);
                //       mBloc.getDefinitions();
                //     },
                //   ),
                // ),
                TdResGaps.v_16,
                SizedBox(
                  // width: double.infinity,
                  child: googleSignInButton(
                    isDense: true,
                    themeColors: themeColors,
                    appThemeDisplay: appThemeDisplay,
                    onPressed: () async {
                      await mBloc.googleLogin();
                    },
                  ),
                ),

                TdResGaps.v_16,

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Google login'),
                    onPressed: () {
                      // Navigate to login page
                    },
                  ),
                ),

                TdResGaps.v_16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Google after login'),
                    onPressed: () {
                      // Navigate to login page  
                    },
                  ),
                ),

                // _widgetMarkdown(),
                BlocBuilder<LabsController, LabsCubitState>(
                  bloc: mBloc,
                  buildWhen:
                      (previous, current) =>
                          current.idToken != previous.idToken,
                  builder: (context, state) {
                    if (state.idToken != null) {
                      return SelectableText(state.idToken!);
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),

                TdResGaps.v_16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Definition Test'),
                    onPressed: () {
                      mBloc.getDefinitions();
                    },
                  ),
                ),

                TdResGaps.v_16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Verse Test'),
                    onPressed: () {
                      mBloc.getVerses();
                    },
                  ),
                ),
                TdResGaps.v_16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Verse Test Stream'),
                    onPressed: () {
                      mBloc.getVerseStreams();
                    },
                  ),
                ),
                TdResGaps.v_16,

                //   HundiButtonWidget(
                // mOnClicked: () {},
                // mTxt: "Get Otp",
                // widthType: HundiButtonWidget.WIDTH_WRAP,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* *****************************************************************************
   *                      modal
   */

  // Auth modal method removed - using new login system
  _modalAuth(int purpose, [String value = '']) {
    // Redirect to login page instead
    // Modular.to.pushNamed('/login');
  }

  // _modalAuth(int authCase, [String value = '']) {
  //   showDialog<AuthRootArgsResult>(
  //     context: context,
  //     builder: (BuildContext context) => AuthRootModal(
  //         mRequestArgs:
  //             AuthRootArgsRequest(purpose: AuthRootUiConstants.PURPOSE_JOIN)),
  //   ).then((value) {
  //     if (value != null &&
  //         value.resultCode == CommonUiConstants.BundleArgs.resultSuccess) {
  //       // checkforAuth();
  //     } else {
  //       mLogger.d("_modalAuth canceled");
  //     }
  //     // if (value != null &&
  //     //     value[CommonUiConstants.BundleArgs.argResultCode] != null &&
  //     //     value[CommonUiConstants.BundleArgs.argResultCode] ==
  //     //         CommonUiConstants.BundleArgs.resultSuccess) {
  //     //           print('modal auth closed to navigate'),
  //     // TODO this.controller.navigateToLink(),
  //     // } else {
  //     //    mLogger.d("auth  canceled"),
  //     //   if (value != null && value[CommonUiConstants.BundleArgs.argMessage] != null) {
  //     //     _showToast(value[CommonUiConstants.BundleArgs.argMessage] as String),
  //     //   }
  //     // }
  //   });
  // }

  Widget _widgetMarkdown() {
    final config =
        themeColors.isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) =>
        MarkdownCodeWrapperWidget(child, text, language);
    return MarkdownWidget(
      data: """w.\nw  qwqw \n## 🌠Night mode

`markdown_widget` supports night mode by default. Simply use a different `MarkdownConfig` to enable it.

```dart
  Widget buildMarkdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    final codeWrapper = (child, text, language) =>
        CodeWrapperWidget(child, text, language);
    return MarkdownWidget(
        data: data,
        config: config.copy(configs: [
        isDark
        ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
        : PreConfig().copy(wrapper: codeWrapper)
    ]));
  }
```
                   """,
      shrinkWrap: true,
      selectable: true,

      config: config.copy(
        configs: [
          themeColors.isDark
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
          // PreConfig(
          //   decoration: BoxDecoration(
          //     color: themeColors?.onSurface.withOpacity(0.04),
          //     borderRadius: BorderRadius.circular(
          //       TdResDimens.dp_16,
          //     ),
          //   ),
          //   theme: a11yLightTheme
          // ),
        ],
      ),
      // config: MarkdownConfig(
      //   configs: [PreConfig(theme: a11yLightTheme)],
      // ),
    );
  }

  prepareTheme(BuildContext context) {
    themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    // mLogger.d("prepareTheme: $themeColors.surface");
  }
}
