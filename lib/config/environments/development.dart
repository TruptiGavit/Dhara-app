import 'package:dharak_flutter/config/env.dart';

class EnvDevelopment extends Env {
  @override
  String get indexRoute => 'labs';

  @override
  String get title => '(D) Dhara';
  
 
  @override
  String get apiUrl => 'https://project.iith.ac.in/bheri';

  
  @override
  String get dashboardDefaultPath => 'dashboard';


  @override
  String get googleSignInClientIdAndroid => "316847997090-rq6reduc42g6qu8lta3l0r8kcj2mfvdt.apps.googleusercontent.com";



}