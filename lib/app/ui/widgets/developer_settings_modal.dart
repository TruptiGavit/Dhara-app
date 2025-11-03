import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';

/// Developer Settings Modal - Bottom sheet with developer options
class DeveloperSettingsModal extends StatefulWidget {
  final AppThemeColors? themeColors;
  
  const DeveloperSettingsModal({
    super.key,
    this.themeColors,
  });

  @override
  State<DeveloperSettingsModal> createState() => _DeveloperSettingsModalState();
}

class _DeveloperSettingsModalState extends State<DeveloperSettingsModal> {
  late final AppThemeColors themeColors;
  final TextEditingController _customApiController = TextEditingController();
  final TextEditingController _testApiController = TextEditingController();
  
  String _selectedApiUrl = DeveloperModeService.defaultProductionUrl;
  AiModel _selectedModel = AiModel.gemini;
  bool _isLoadingApiTest = false;
  Map<String, dynamic>? _apiTestResult;
  bool _isUnifiedTabEnabled = false;
  
  @override
  void initState() {
    super.initState();
    themeColors = widget.themeColors ?? 
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    
    _loadCurrentSettings();
    _loadCustomApiEndpoint();
  }
  
  @override
  void dispose() {
    _customApiController.dispose();
    _testApiController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentSettings() async {
    setState(() {
      _selectedApiUrl = DeveloperModeService.instance.currentApiUrl;
      _selectedModel = DeveloperModeService.instance.preferredModel;
      _isUnifiedTabEnabled = DeveloperModeService.instance.isUnifiedTabEnabled;
    });
    _customApiController.text = _selectedApiUrl;
  }
  
  Future<void> _loadCustomApiEndpoint() async {
    final customEndpoint = await DeveloperModeService.instance.getCustomApiEndpoint();
    if (customEndpoint != null) {
      _testApiController.text = customEndpoint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TdResDimens.dp_20),
          topRight: Radius.circular(TdResDimens.dp_20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: TdResDimens.dp_12),
            decoration: BoxDecoration(
              color: themeColors.onSurface?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          TdResGaps.v_20,
          
          // Header with title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Developer Settings',
                    style: TdResTextStyles.h2.copyWith(
                      color: themeColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: themeColors.onSurface?.withOpacity(0.7),
                  ),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          
          TdResGaps.v_24,
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildApiUrlSection(),
                  TdResGaps.v_24,
                  _buildModelSelectionSection(),
                  TdResGaps.v_24,
                  _buildUIFeaturesSection(),
                  TdResGaps.v_24,
                  _buildApiTestingSection(),
                  TdResGaps.v_32,
                  _buildLogoutSection(),
                  TdResGaps.v_36,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApiUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. API URL Configuration',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        TdResGaps.v_12,
        Text(
          'Choose or edit the API base URL:',
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
          ),
        ),
        TdResGaps.v_16,
        
        // Predefined options
        ...DeveloperModeService.instance.getPredefinedApiUrls().map((url) => 
          _buildApiUrlOption(url),
        ),
        
        TdResGaps.v_12,
        
        // Custom URL input
        Text(
          'Custom URL:',
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        TdResGaps.v_8,
        TextField(
          controller: _customApiController,
          decoration: InputDecoration(
            hintText: 'Enter custom API URL',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TdResDimens.dp_8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TdResDimens.dp_16,
              vertical: TdResDimens.dp_12,
            ),
          ),
          style: TdResTextStyles.h6.copyWith(color: themeColors.onSurface),
        ),
        TdResGaps.v_12,
        
        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyApiUrl,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primary,
              foregroundColor: themeColors.surface,
              padding: const EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TdResDimens.dp_8),
              ),
            ),
            child: Text(
              'Apply API URL',
              style: TdResTextStyles.h6.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildApiUrlOption(String url) {
    final isSelected = _selectedApiUrl == url;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedApiUrl = url;
          _customApiController.text = url;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: TdResDimens.dp_8),
        padding: const EdgeInsets.all(TdResDimens.dp_12),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeColors.primary?.withOpacity(0.1) 
              : themeColors.surface,
          border: Border.all(
            color: isSelected 
                ? themeColors.primary ?? Colors.blue
                : themeColors.onSurface?.withOpacity(0.2) ?? Colors.grey,
          ),
          borderRadius: BorderRadius.circular(TdResDimens.dp_8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? themeColors.primary : themeColors.onSurface?.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: TdResDimens.dp_12),
            Expanded(
              child: Text(
                url,
                style: TdResTextStyles.h6.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModelSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. AI Model Selection',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        TdResGaps.v_12,
        Text(
          'Choose the preferred AI model for Prashna:',
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
          ),
        ),
        TdResGaps.v_16,
        
        // Model options
        ...AiModel.values.map((model) => _buildModelOption(model)),
        
        TdResGaps.v_12,
        
        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyModel,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primary,
              foregroundColor: themeColors.surface,
              padding: const EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TdResDimens.dp_8),
              ),
            ),
            child: Text(
              'Apply Model Selection',
              style: TdResTextStyles.h6.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildModelOption(AiModel model) {
    final isSelected = _selectedModel == model;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedModel = model;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: TdResDimens.dp_8),
        padding: const EdgeInsets.all(TdResDimens.dp_12),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeColors.primary?.withOpacity(0.1) 
              : themeColors.surface,
          border: Border.all(
            color: isSelected 
                ? themeColors.primary ?? Colors.blue
                : themeColors.onSurface?.withOpacity(0.2) ?? Colors.grey,
          ),
          borderRadius: BorderRadius.circular(TdResDimens.dp_8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? themeColors.primary : themeColors.onSurface?.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: TdResDimens.dp_12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayName,
                    style: TdResTextStyles.h6.copyWith(
                      color: themeColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    model.description,
                    style: TdResTextStyles.buttonSmall.copyWith(
                      color: themeColors.onSurface?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUIFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. UI Features',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        TdResGaps.v_12,
        Text(
          'Enable experimental UI features:',
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
          ),
        ),
        TdResGaps.v_16,
        
        // Unified Tab Toggle
        _buildToggleOption(
          title: 'Unified Search Tab',
          description: 'Adds a unified search tab in quick search',
          value: _isUnifiedTabEnabled,
          onChanged: (value) {
            setState(() {
              _isUnifiedTabEnabled = value;
            });
            _applyUnifiedTabSetting();
          },
        ),
      ],
    );
  }
  
  Widget _buildToggleOption({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(TdResDimens.dp_16),
      decoration: BoxDecoration(
        color: themeColors.onSurface?.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TdResDimens.dp_8),
        border: Border.all(
          color: themeColors.onSurface?.withOpacity(0.1) ?? Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TdResTextStyles.h6.copyWith(
                    color: themeColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TdResGaps.v_4,
                Text(
                  description,
                  style: TdResTextStyles.buttonSmall.copyWith(
                    color: themeColors.onSurface?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildApiTestingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. API Testing',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        TdResGaps.v_12,
        Text(
          'Test custom API endpoints:',
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
          ),
        ),
        TdResGaps.v_16,
        
        // API endpoint input
        TextField(
          controller: _testApiController,
          decoration: InputDecoration(
            hintText: 'e.g., /dict/v1/get_defs/?word=nayana',
            helperText: 'Relative URLs will use current base URL: $_selectedApiUrl',
            helperMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TdResDimens.dp_8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TdResDimens.dp_16,
              vertical: TdResDimens.dp_12,
            ),
          ),
          style: TdResTextStyles.h6.copyWith(color: themeColors.onSurface),
          maxLines: 2,
          minLines: 1,
        ),
        TdResGaps.v_12,
        
        // Test button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoadingApiTest ? null : _testApiEndpoint,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primary,
              foregroundColor: themeColors.surface,
              padding: const EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TdResDimens.dp_8),
              ),
            ),
            child: _isLoadingApiTest
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Test API Endpoint',
                    style: TdResTextStyles.h6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        // Test result
        if (_apiTestResult != null) ...[
          TdResGaps.v_16,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TdResDimens.dp_16),
            decoration: BoxDecoration(
              color: themeColors.onSurface?.withOpacity(0.05),
              borderRadius: BorderRadius.circular(TdResDimens.dp_8),
              border: Border.all(
                color: themeColors.onSurface?.withOpacity(0.1) ?? Colors.grey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _apiTestResult!['success'] == true 
                          ? Icons.check_circle 
                          : Icons.error,
                      color: _apiTestResult!['success'] == true 
                          ? Colors.green 
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: TdResDimens.dp_8),
                    Text(
                      'API Test Result',
                      style: TdResTextStyles.h6.copyWith(
                        color: themeColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _copyTestResult,
                      icon: Icon(
                        Icons.copy,
                        size: 18,
                        color: themeColors.onSurface?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                TdResGaps.v_8,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_apiTestResult),
                    style: TdResTextStyles.buttonSmall.copyWith(
                      color: themeColors.onSurface?.withOpacity(0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildLogoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developer Mode',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        TdResGaps.v_12,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _logoutDeveloperMode,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TdResDimens.dp_8),
              ),
            ),
            child: Text(
              'Logout from Developer Mode',
              style: TdResTextStyles.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _applyApiUrl() async {
    final url = _customApiController.text.trim();
    if (url.isNotEmpty) {
      await DeveloperModeService.instance.setApiUrl(url);
      _showSuccessMessage('API URL updated successfully');
    }
  }
  
  Future<void> _applyModel() async {
    await DeveloperModeService.instance.setPreferredModel(_selectedModel);
    _showSuccessMessage('Preferred model updated successfully');
  }
  
  Future<void> _applyUnifiedTabSetting() async {
    await DeveloperModeService.instance.setUnifiedTabEnabled(_isUnifiedTabEnabled);
    _showSuccessMessage(_isUnifiedTabEnabled 
        ? 'Unified tab enabled' 
        : 'Unified tab disabled');
  }
  
  Future<void> _testApiEndpoint() async {
    final endpoint = _testApiController.text.trim();
    if (endpoint.isEmpty) return;
    
    setState(() {
      _isLoadingApiTest = true;
      _apiTestResult = null;
    });
    
    try {
      // Save the custom endpoint
      await DeveloperModeService.instance.saveCustomApiEndpoint(endpoint);
      
      // Construct full URL if endpoint is relative
      String fullUrl = endpoint;
      if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
        // Use current API URL as base
        final baseUrl = _selectedApiUrl;
        fullUrl = endpoint.startsWith('/') 
            ? '$baseUrl$endpoint' 
            : '$baseUrl/$endpoint';
      }
      
      // Test the endpoint
      final result = await DeveloperModeService.instance.testApiEndpoint(fullUrl);
      
      setState(() {
        _apiTestResult = {
          ...result,
          'testedUrl': fullUrl, // Add the tested URL for reference
        };
      });
    } catch (e) {
      setState(() {
        _apiTestResult = {
          'success': false,
          'error': 'Exception',
          'message': e.toString(),
        };
      });
    } finally {
      setState(() {
        _isLoadingApiTest = false;
      });
    }
  }
  
  void _copyTestResult() {
    if (_apiTestResult != null) {
      final jsonString = const JsonEncoder.withIndent('  ').convert(_apiTestResult);
      Clipboard.setData(ClipboardData(text: jsonString));
      _showSuccessMessage('Test result copied to clipboard');
    }
  }
  
  Future<void> _logoutDeveloperMode() async {
    await DeveloperModeService.instance.logout();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged out from developer mode'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
