import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';

/// Dialog for developer mode authentication
class DeveloperAuthDialog extends StatefulWidget {
  final AppThemeColors? themeColors;
  
  const DeveloperAuthDialog({
    super.key,
    this.themeColors,
  });

  @override
  State<DeveloperAuthDialog> createState() => _DeveloperAuthDialogState();
}

class _DeveloperAuthDialogState extends State<DeveloperAuthDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showError = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_passwordController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _showError = false;
    });
    
    try {
      final success = await DeveloperModeService.instance.authenticate(_passwordController.text);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _showError = true;
          _passwordController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _passwordController.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.themeColors;
    
    return AlertDialog(
      backgroundColor: colors?.surface ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.developer_mode,
            color: colors?.primaryHigh ?? Colors.indigo.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Developer Access',
            style: TextStyle(
              color: colors?.onSurface ?? Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter developer password to access advanced features:',
            style: TextStyle(
              color: colors?.onSurfaceMedium ?? Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: colors?.onSurfaceMedium ?? Colors.grey.shade600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colors?.primaryLight ?? Colors.indigo.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colors?.primary ?? Colors.indigo,
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: colors?.onSurfaceMedium ?? Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              errorText: _showError ? 'Invalid password' : null,
            ),
            style: TextStyle(
              color: colors?.onSurface ?? Colors.black,
            ),
            onSubmitted: (_) => _authenticate(),
          ),
          
          if (_showError) ...[
            const SizedBox(height: 8),
            Text(
              'Access denied. Please check your password.',
              style: TextStyle(
                color: colors?.errorColor ?? Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colors?.onSurfaceMedium ?? Colors.grey.shade600,
            ),
          ),
        ),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _authenticate,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors?.primary ?? Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Authenticate'),
        ),
      ],
    );
  }
}




