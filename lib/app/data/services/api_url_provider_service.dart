import 'dart:async';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/flavors.dart';

/// Service that provides the current API URL based on developer mode settings
class ApiUrlProviderService {
  static ApiUrlProviderService? _instance;
  static ApiUrlProviderService get instance => _instance ??= ApiUrlProviderService._();
  
  ApiUrlProviderService._();
  
  final StreamController<String> _apiUrlController = StreamController<String>.broadcast();
  String _currentApiUrl = '';
  bool _isInitialized = false;
  
  /// Stream to listen to API URL changes
  Stream<String> get apiUrlStream => _apiUrlController.stream;
  
  /// Get current API URL
  String get currentApiUrl => _currentApiUrl;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize developer mode service first
    await DeveloperModeService.instance.initialize();
    
    // Set initial URL
    _updateApiUrl();
    
    // Listen to developer mode authentication changes
    DeveloperModeService.instance.authStateStream.listen((isAuthenticated) {
      _updateApiUrl();
    });
    
    // Listen to developer mode API URL changes
    DeveloperModeService.instance.apiUrlStream.listen((url) {
      _updateApiUrl();
    });
    
    _isInitialized = true;
  }
  
  void _updateApiUrl() {
    String newUrl;
    
    if (DeveloperModeService.instance.isAuthenticated) {
      // Use developer mode URL if authenticated
      newUrl = DeveloperModeService.instance.currentApiUrl;
    } else {
      // Use default environment URL
      newUrl = F.apiUrl;
    }
    
    if (_currentApiUrl != newUrl) {
      _currentApiUrl = newUrl;
      _apiUrlController.add(newUrl);
    }
  }
  
  /// Dispose the service
  void dispose() {
    _apiUrlController.close();
  }
}



