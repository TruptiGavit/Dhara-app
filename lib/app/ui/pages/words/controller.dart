import 'dart:async';

// import 'package:common/app/domain/base/domain_result.dart';

import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:dharak_flutter/app/ui/pages/words/args.dart';
import 'package:dharak_flutter/app/ui/pages/words/cubit_states.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
// import 'package:common/app/types/account/account_common.dart';

class WordDefineController extends Cubit<WordDefineCubitState> {
  var mLogger = Logger();

  final TextEditingController mSearchController = TextEditingController();

  final DictionaryRepository mDictionaryRepository;

  final AuthAccountRepository mAuthAccountRepository;

  StreamSubscription<UserRM?>? _mAccountCommonSubscription;
  StreamSubscription<String>? _mSearchQuerySubscription;

  Timer? _mSearchDebounce;

  WordDefineController({
    // required this.mVendorsRepo,
    required this.mAuthAccountRepository,
    required this.mDictionaryRepository,
  }) : super(
         WordDefineCubitState(
           // isLoading: true,
           // state: AuthRootUiConstants.STATE_DEFAULT,
           // purpose: AuthEmailUiConstants.STATE_DEFAULT
         ),
       ) {
    _formCreate();
  }

  @override
  Future<void> close() {
    _mAccountCommonSubscription?.cancel();

    mSearchController.dispose();
    _mSearchDebounce?.cancel();
    _mSearchQuerySubscription?.cancel();
    return super.close();
  }

  Future<void> initData(WordDefineArgsRequest args) async {
    _subscribeBloc();

    // _mEventRefresh.sink.add(true);
  }

  void _subscribeBloc() {
    _mSearchQuerySubscription =
        mDictionaryRepository.mEventSearchQuery.listen(
      (value) {
        onSearchDirectQuery(value);
      },
    );
  }

  // Future<void> onClickLogout() async {
  //   await mAuthAccountRepository.logout();
  // }

  onFormSearchTextChanged(String? text) {
    if (_mSearchDebounce?.isActive ?? false) _mSearchDebounce?.cancel();

    // Set up a new timer
    // _mSearchDebounce = Timer(const Duration(milliseconds: 1000), () {
    //   // Perform your action here, e.g., API call
    //   print('Debounced Input: $text');
    //   // TODO call api;

    //   _loadDefine();
    // });

    if (text == null) {
      mSearchController.clear();
    }

    emit(state.copyWith(formSearchText: text));
  }

  onSearchDirectQuery(String word) async {
    mSearchController.value = TextEditingValue(
      text: word,
      selection: TextSelection.fromPosition(TextPosition(offset: word.length)),
    );
    emit(state.copyWith(formSearchText: word));

    await _loadDefine();
  }

  onFormSubmit() async {
    // emit(state.copyWith(f))
    await _loadDefine();
    // formValidate();
  }

  /*          *************************************************************8
   *                      form
   */

  _formCreate() {
    print("_formCreate ....");

    stream.listen((value) {
      formValidate();
    });
  }

  formValidate() {
    // var controls = this._mFormGroup.values.toList();
    //mLogger.d("---------------------------------------------------------");

    var isValid = true;

    // print("form validate with state 2: $isValid ${state.details}");
    // if (!mFormControllerMedia.isValid()) {
    //   isValid = false;
    //   //mLogger.d("validate message: titleController");
    // }

    if (isValid) {
      isValid = formHasChanges();
      // print("form validate with state: $isValid ${state.store} ${state.name}");
    }

    emit(state.copyWith(isSubmitEnabled: isValid));

    // }

    // add(CommuneEditValidationBlocEvent(isValid));
  }

  bool formHasChanges() {
    // if (state.product?.categoryId != state.formCategory?.id) {

    // print("formHasChanges state: 3");
    var hasChanges = false;
    if (!UtilString.isStringsEmpty(state.formSearchText) &&
        !UtilString.areStringsEqualOrNull(
          state.searchQuery,
          state.formSearchText,
        )) {
      return true;
    }

    return hasChanges;

    // print("formHasChanges state: 3");
  }

  /* **************************************************************************************
   *                                      domain 
   */

  _load() async {
    if (state.isInitialized == false) {
      emit(
        state.copyWith(
          // purpose: args.purpose,
          isInitialized: true,
          // state: uiState,
          isLoading: false,
        ),
      );
    }
  }

  Future<bool> _loadDefine() async {
    var searchQuery = state.formSearchText;

    if (searchQuery == null) {
      return false;
    }
    emit(state.copyWith(isLoading: true));

    var result = await this.mDictionaryRepository.getDefinition(
      word: searchQuery ?? "",
    );

    emit(state.copyWith(isLoading: false));
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      print("getDefinitions: ${result}");
      // emit(state.copyWith(order: result.data));
      // ;

      emit(
        state.copyWith(
          wordDetails: result.data?.details,
          similarWords: result.data?.similarWords ?? []
                  ,
          dictWordDefinitions: result.data,
          searchCounter: state.searchCounter + 1,
          wordDefinitions: result.data?.details.definitions ?? [],
          searchQuery: searchQuery,
        ),
      );

      print("getDefinitions 2: ${result.data?.details.definitions}");
      return true;
    }else if(result.errorCode!=null){
    print("getDefinitions 3: ${result.message}");

    }
    print("getDefinitions 4: ${result}");

    return false;
  }

  String getAllText() {
    return state.wordDefinitions.fold("", (text, e) {
      return "$text ${e.text} \n";
    });
  }

  /* *****************************************************************************
   *                              Form
   */
}
