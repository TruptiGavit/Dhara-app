import 'dart:async';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing developer mode settings and preferences
/// This handles authentication and model preferences for development/testing
class DeveloperModeService {
  static final DeveloperModeService _instance = DeveloperModeService._internal();
  static DeveloperModeService get instance => _instance;
  
  final Logger _logger = Logger();
  
  // Private constructor
  DeveloperModeService._internal();
  
  // ===== AUTHENTICATION STATE =====
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  
  // ===== PREFERRED MODEL MANAGEMENT =====
  final BehaviorSubject<AiModel> _preferredModelSubject = BehaviorSubject.seeded(AiModel.qwen);
  Stream<AiModel> get preferredModelStream => _preferredModelSubject.stream;
  AiModel get preferredModel => _preferredModelSubject.value;
  
  // ===== API URL MANAGEMENT =====
  String? _currentApiUrl;
  String? get currentApiUrl => _currentApiUrl;
  
  // ===== INITIALIZATION =====
  
  /// Initialize developer mode service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _logger.d('✅ DeveloperModeService initialized');
    } catch (e) {
      _logger.e('❌ Error initializing DeveloperModeService', error: e);
    }
  }
  
  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load authentication state
      _isAuthenticated = prefs.getBool('dev_mode_authenticated') ?? false;
      
      // Load preferred model
      final modelString = prefs.getString('dev_mode_preferred_model');
      if (modelString != null) {
        final model = AiModel.values.firstWhere(
          (m) => m.modelParameter == modelString,
          orElse: () => AiModel.qwen,
        );
        _preferredModelSubject.add(model);
      }
      
      // Load API URL
      _currentApiUrl = prefs.getString('dev_mode_api_url');
      
      _logger.d('🔧 Developer mode settings loaded: authenticated=$_isAuthenticated, model=${preferredModel.displayName}');
    } catch (e) {
      _logger.e('❌ Error loading developer mode settings', error: e);
    }
  }
  
  /// Save settings to shared preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('dev_mode_authenticated', _isAuthenticated);
      await prefs.setString('dev_mode_preferred_model', preferredModel.modelParameter);
      
      if (_currentApiUrl != null) {
        await prefs.setString('dev_mode_api_url', _currentApiUrl!);
      }
      
      _logger.d('💾 Developer mode settings saved');
    } catch (e) {
      _logger.e('❌ Error saving developer mode settings', error: e);
    }
  }
  
  // ===== AUTHENTICATION METHODS =====
  
  /// Authenticate developer mode (for testing/development)
  Future<void> authenticate(String password) async {
    // Simple password check for development
    if (password == 'dev123' || password == 'developer') {
      _isAuthenticated = true;
      await _saveSettings();
      _logger.d('🔐 Developer mode authenticated');
    } else {
      throw Exception('Invalid developer password');
    }
  }
  
  /// Logout from developer mode
  Future<void> logout() async {
    _isAuthenticated = false;
    await _saveSettings();
    _logger.d('🔓 Developer mode logged out');
  }
  
  // ===== MODEL PREFERENCE METHODS =====
  
  /// Set preferred AI model
  Future<void> setPreferredModel(AiModel model) async {
    _preferredModelSubject.add(model);
    await _saveSettings();
    _logger.d('🎯 Preferred model changed to: ${model.displayName}');
  }
  
  // ===== API URL METHODS =====
  
  /// Set custom API URL for development
  Future<void> setApiUrl(String? url) async {
    _currentApiUrl = url;
    await _saveSettings();
    _logger.d('🌐 API URL set to: ${url ?? "default"}');
  }
  
  // ===== CLEANUP =====
  
  /// Dispose resources
  void dispose() {
    _preferredModelSubject.close();
  }
  
  // ===== UTILITY METHODS =====
  
  /// Reset all developer mode settings
  Future<void> reset() async {
    _isAuthenticated = false;
    _currentApiUrl = null;
    _preferredModelSubject.add(AiModel.qwen);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dev_mode_authenticated');
    await prefs.remove('dev_mode_preferred_model');
    await prefs.remove('dev_mode_api_url');
    
    _logger.d('🔄 Developer mode settings reset');
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAuthenticated': _isAuthenticated,
      'preferredModel': preferredModel.displayName,
      'apiUrl': _currentApiUrl ?? 'default',
    };
  }
}








