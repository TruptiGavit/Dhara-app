
import 'package:dharak_flutter/app/ui/widgets/buttons/button_widget.dart';
import 'package:dharak_flutter/app/ui/widgets/shapes/clips/clip_circle_bottom.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';

class Error404Modal extends StatefulWidget {
  final String title;
  final Function() onRetry;
  const Error404Modal({Key? key, required this.onRetry, this.title = "CommonLoadErrorWidget"})
      : super(key: key);

  @override
  Error404ModalState createState() => Error404ModalState();

  // @override
  // Widget build(BuildContext context) {
  //   return Container(child: Text(title));
  // }

}

class Error404ModalState extends State<Error404Modal> {
  var mLogger = Logger();

 late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;
  // Color _mColorOnSurface = Colors.black;
  // Color _mColorSurface = Colors.white;

  // Color _mColorOnSurfaceMedium = Colors.black54;
  // Color _mColorOnSurfaceDisable = Colors.black38;

  // Color _mColorPrimaryHigh = Colors.greenAccent;
  // Color _mColorPrimary = Colors.green;

  // Color _mColorOnSurfaceLowest = Colors.black12;

  final GlobalKey<ScaffoldState> _mScaffoldKey = GlobalKey<ScaffoldState>();

  // Color _mColorBack = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    return PopScope(
      canPop: () {
        return true;
      }(),
      child: Scaffold(
        key: _mScaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: _widgetAppbar(context),
        body: Container(
          child: _widgetContents(context),
        ),
      ),
    );
  }

  _widgetContents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TdResGaps.v_44,
        // Container(
        //   height: 40,
        //   width: 40,
        //   color: Colors.white,
        // ),
        Expanded(
          flex: 1,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipPath(
                clipper: ClipCircleBottom(),
                child: Container(
                  margin: EdgeInsets.all(TdResDimens.dp_32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColors.surface,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(0.8, 0.5), // near the top right
                          radius: 0.7,
                          colors: <Color>[
                            themeColors.onSurfaceLowest,
                            themeColors.surface
                            ],
                          stops: <double>[0.0, 1.0],
                        )),
                  ),
                ),
              ),
              Container(
                // margin: EdgeInsets.all(TdResDimens.dp_32),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/img/pic_error_load.png'),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter),
                ),
              )
            ],
          ),
        ),

        TdResGaps.v_56,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: "Failed to Load !! ",
                    style: TdResTextStyles.h2.merge(
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                    children: <InlineSpan>[
                      TextSpan(
                          text: 'Please wait and retry again.',
                          style: TdResTextStyles.h2.merge(
                            TextStyle(color: themeColors.onSurface),
                          )),
                    ],
                  ),
                ),
              ),
              TdResGaps.v_44,
              // Text(
              //   'You will receive 4 digit code to verify next',
              //   style: TdResTextStyles.p1
              //       .merge(TextStyle(color: _mColorOnSurfaceMedium)),
              // ),
            ],

            // subtitle: RichText(
            //   text: TextSpan(
            //     text: 'Need Your help to explore the ',
            //     style: TdResTextStyles.h5
            //         .merge(TextStyle(color: _mColorOnSurfaceMedium)),
            //     children: const <TextSpan>[
            //       TextSpan(
            //         text: 'truth',
            //         style: TextStyle(color: TbResColors.colorPrimary),
            //       ),
            //       TextSpan(text: ' around us'),
            //     ],
            //   ),
            // ),
          ),
        ),

        TdResGaps.v_20,

        // TdResGaps.v_20,
        _widgetActions(context),
        TdResGaps.v_12,

        TdResGaps.v_44,
      ],
    );
  }

  Widget _widgetInput(BuildContext context) {
    var textFormField = TextFormField(
      style: TdResTextStyles.h3.merge(TextStyle(color: themeColors.onSurface)),
      autofocus: true,
      maxLines: 1,
      //TODO  focusNode: controller.formController.titleController.focusNode,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      // textCapitalization: TextCapitalization.sentences,
      onChanged: (String value) {
        // print("_widgetForm");
        // TODO controller.formController.titleController.onChanged(value);
        // _formKey.currentState.save();
        // return null;
      },
      //todo "CHECKTHIS" commented due to error
      // TODO validator: controller.formController.titleController.validator!,

      //      (value) {
      //   if (value!.isEmpty) {
      //     return 'Please enter some text';
      //   }
      //   return null;
      // },
      // validator: (String value) {
      //   if (value == null || value.length < 1) {
      //     return '';
      //   }
      //   // _formKey.currentState.save();
      //   return null;
      // },
      onSaved: (value) {
        // print("onSaved: ${value}");
        // _mFormTitle = value;
      },
      onFieldSubmitted: (term) {
        /*
        TODO 
        if (mFormState == TalesCreatorConstants.FORM_STATE_INITIAL) {
          controller.formController
              .setState(TalesCreatorConstants.FORM_STATE_TITLE_ADDED);
          // setState(() {
          //   mFormState = TalesCreatorConstants.FORM_STATE_TITLE_ADDED;
          //   // return;
          // });
        }
        controller.formController
            .focusNext(controller.formController.KEY_TITLE);*/

        // FocusScope.of(context).requestFocus(lname);
      },
      decoration: InputDecoration(
        border: InputBorder.none,
        // border: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: new BorderSide(color: Colors.grey.shade100)),
        hintText: "type 9863 ..",
        hintStyle:
            TdResTextStyles.h3.merge(TextStyle(color: themeColors.onSurfaceDisable)),
        contentPadding: EdgeInsets.only(left: 10, right: 10, bottom: 0, top: 0),
      ),
    );

    return textFormField;

    // return [
    //   Align(
    //     alignment: Alignment.centerRight,
    //     child: Padding(
    //       padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_16),
    //       child: StreamBuilder(
    //           stream: controller.formController.detailsController.value.stream,
    //           builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
    //             // print("isRunningPageState : ${snapshot.data}");
    //             return Text(
    //               "${snapshot.data?.length ?? 0}/${controller.formController.LENGTH_TITLE}",
    //               style: TdResTextStyles.caption.merge(
    //                 TextStyle(color: _mColorOnSurfaceMedium),
    //               ),
    //             );
    //           }),
    //     ),
    //   ),
    //   Container(
    //     padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_12),
    //     child: textFormField,
    //   ),
    // ];
  }

  Widget _widgetActions(BuildContext context) {
    // var colorPrimaryLowest = TbThemeHelper.colorBlend(context,
    //     TbThemeColor.surface, TbThemeColor.primary, TbColorEmphasize.disabled);
    // var colorPrimaryHigh = TbThemeHelper.colorBlend(context,
    //     TbThemeColor.surface, TbThemeColor.primary, TbColorEmphasize.high);

    // final mFormController = TextEditingController();
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_32),
        child: TdButtonWidget(
            mOnClicked: () {widget.onRetry();},
            mTxt: "Retry",
            widthType: TdButtonWidget.WIDTH_WRAP,
            isRtl: true,
            isSecondary: true,
            mIconData: Icons.new_releases_rounded),
      ),
    );
  }

  PreferredSizeWidget _widgetAppbar(BuildContext context) {
    // print(_mCollection);

    // inspect(_mCollection);

    // var primaryColor = Theme.of(context).colorScheme

    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        "",
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TdResTextStyles.h5,
      ),
      leading: IconButton(
        icon: Icon(
          Icons.keyboard_arrow_left_rounded,
        ),
        onPressed: () {
          Modular.to.maybePop();
        },
      ),
      // leading: Padding(
      //   padding: EdgeInsets.all(TdResDimens.dp_8),
      //   child: Ink(
      //     decoration: ShapeDecoration(
      //       color: TbResColors.black6,
      //       shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(TdResDimens.dp_12)),
      //     ),
      //     child: IconButton(
      //       icon: Icon(
      //         AgyanIcons.long_arrow_alt_left,
      //         size: 18.0,
      //         color: Colors.grey.shade900,
      //       ),
      //       onPressed: () {
      //         Modular.to.maybePop();
      //       },
      //     ),
      //   ),
      // ),
      actions: [
        // IconButton(
        //   icon: Icon(
        //     Icons.more_vert,
        //     color: Colors.grey.shade900,
        //   ),
        //   onPressed: () => debugPrint("more vert"),
        // )
      ],
    );
  }

/* *********************************************************************************
 *                                      theme
 */

prepareTheme(BuildContext context) {
   
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    // mLogger.d("prepareTheme: $themeColors.surface");
  }


  // prepareTheme(BuildContext context) {
  //   _mColorPrimaryHigh = TbThemeHelper.colorBlend(context, TbThemeColor.surface,
  //       TbThemeColor.primary, TbColorEmphasize.high);
  //   _mColorPrimary = Theme.of(context).colorScheme.primary;

  //   _mColorOnSurface = TbThemeHelper.colorBlend(
  //       context,
  //       TbThemeColor.background,
  //       TbThemeColor.onSurface,
  //       TbColorEmphasize.original);

  //   _mColorOnSurfaceMedium = TbThemeHelper.color(
  //       context, TbThemeColor.onSurface, TbColorEmphasize.medium);

  //   _mColorSurface = TbThemeHelper.color(
  //       context, TbThemeColor.surface, TbColorEmphasize.original);

  //   _mColorOnSurfaceDisable = TbThemeHelper.color(
  //       context, TbThemeColor.onSurface, TbColorEmphasize.disabled);

  //   _mColorOnSurfaceLowest = TbThemeHelper.colorBlend(
  //       context,
  //       TbThemeColor.background,
  //       TbThemeColor.onSurface,
  //       TbColorEmphasize.lowest);

  //   _mColorBack = TbThemeHelper.color(
  //       context, TbThemeColor.background, TbColorEmphasize.original);

  //   mLogger.d("prepareTheme: $_mColorSurface");
  // }
}
