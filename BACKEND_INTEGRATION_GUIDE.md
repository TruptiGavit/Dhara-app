# Backend Integration Guide for Google Login (Web)

## 🚨 Current Issue

**Error**: `{"error": "Invalid token"}` when calling `/bheri/api/google_login/`

**Cause**: The backend is receiving OAuth **access tokens** from web clients, but may be expecting **ID tokens** or not validating them correctly.

---

## 🔍 Understanding Token Types

### ID Token (JWT)
- Contains user identity information
- Signed by Google (can be verified offline)
- Format: `eyJhbGciOiJSUzI1NiIs...` (3 parts separated by dots)
- **Mobile apps** typically get these
- Can be verified without calling Google API

### Access Token (OAuth)
- Used to access Google APIs
- Format: `ya29.a0AQQ_BDR...` (long string)
- **Web apps** typically get these from `google_sign_in` package
- **Must be validated by calling Google API**

---

## ✅ Solution: Update Backend to Handle Both

Your Django backend needs to:
1. Accept access tokens from web clients
2. Validate them with Google
3. Extract user information
4. Return JWT tokens for your app

---

## 🔧 Django Implementation

### Option 1: Validate Access Token (Recommended for Web)

```python
# views.py
import requests
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

@api_view(['POST'])
def google_login(request):
    """
    Handle Google OAuth login from web and mobile clients.
    Accepts access_token from web or id_token from mobile.
    """
    token = request.data.get('access_token')
    
    if not token:
        return Response(
            {'error': 'Token missing'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Try to validate as access token first (for web)
    user_info = validate_google_access_token(token)
    
    # If that fails, try as ID token (for mobile)
    if not user_info:
        user_info = validate_google_id_token(token)
    
    if not user_info:
        return Response(
            {'error': 'Invalid token'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Create or get user
    user = get_or_create_user(user_info)
    
    # Generate your JWT tokens
    access_token, refresh_token = generate_jwt_tokens(user)
    
    return Response({
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': {
            'email': user.email,
            'name': user.name,
            'picture': user.picture,
        }
    })


def validate_google_access_token(access_token):
    """
    Validate Google OAuth access token by calling Google's API.
    This is what web clients send.
    """
    try:
        # Call Google's tokeninfo endpoint
        response = requests.get(
            'https://www.googleapis.com/oauth2/v3/tokeninfo',
            params={'access_token': access_token},
            timeout=5
        )
        
        if response.status_code == 200:
            token_info = response.json()
            
            # Verify the token is valid
            if 'email' in token_info and token_info.get('email_verified'):
                return {
                    'email': token_info['email'],
                    'name': token_info.get('name', ''),
                    'picture': token_info.get('picture', ''),
                    'email_verified': token_info.get('email_verified', False),
                }
        
        return None
    except Exception as e:
        print(f"Error validating access token: {e}")
        return None


def validate_google_id_token(id_token):
    """
    Validate Google ID token (JWT).
    This is what mobile clients typically send.
    """
    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests
        
        # Verify the token
        id_info = google_id_token.verify_oauth2_token(
            id_token,
            google_requests.Request(),
            None  # Or specify your client ID
        )
        
        if id_info.get('email_verified'):
            return {
                'email': id_info['email'],
                'name': id_info.get('name', ''),
                'picture': id_info.get('picture', ''),
                'email_verified': id_info.get('email_verified', False),
            }
        
        return None
    except Exception as e:
        print(f"Error validating ID token: {e}")
        return None


def get_or_create_user(user_info):
    """
    Get or create user from Google info.
    Adapt this to your User model.
    """
    from django.contrib.auth import get_user_model
    
    User = get_user_model()
    
    user, created = User.objects.get_or_create(
        email=user_info['email'],
        defaults={
            'username': user_info['email'],
            'name': user_info['name'],
            'picture': user_info['picture'],
        }
    )
    
    if not created:
        # Update existing user
        user.name = user_info['name']
        user.picture = user_info['picture']
        user.save()
    
    return user


def generate_jwt_tokens(user):
    """
    Generate your app's JWT access and refresh tokens.
    Adapt this to your JWT implementation.
    """
    from rest_framework_simplejwt.tokens import RefreshToken
    
    refresh = RefreshToken.for_user(user)
    
    return str(refresh.access_token), str(refresh)
```

### Option 2: Use Google Auth Library (Alternative)

```python
# Install: pip install google-auth google-auth-oauthlib google-auth-httplib2

from google.oauth2 import id_token
from google.auth.transport import requests

def verify_google_token(token_string):
    """
    Universal token verification - works for both ID and access tokens.
    """
    try:
        # First try as ID token
        id_info = id_token.verify_oauth2_token(
            token_string, 
            requests.Request()
        )
        
        if id_info.get('email_verified'):
            return id_info
            
    except Exception:
        # If ID token verification fails, try as access token
        try:
            response = requests.get(
                'https://www.googleapis.com/oauth2/v3/tokeninfo',
                params={'access_token': token_string}
            )
            
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            print(f"Token verification failed: {e}")
    
    return None
```

---

## 📦 Required Python Packages

Add to `requirements.txt`:

```txt
google-auth>=2.23.0
google-auth-oauthlib>=1.1.0
google-auth-httplib2>=0.1.1
requests>=2.31.0
```

Install:
```bash
pip install google-auth google-auth-oauthlib google-auth-httplib2
```

---

## 🧪 Testing

### Test Access Token Validation

```python
# test_google_auth.py
import requests

def test_access_token_validation():
    """
    Test that your endpoint accepts access tokens.
    """
    # This is a sample access token from Google OAuth
    access_token = "ya29.a0AQQ_BDR..."  # Your actual token from logs
    
    response = requests.post(
        'https://project.iith.ac.in/bheri/api/google_login/',
        json={'access_token': access_token}
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    
    assert response.status_code == 200
    assert 'access_token' in response.json()
    assert 'user' in response.json()

# Run with: pytest test_google_auth.py -v
```

### Manual Testing with curl

```bash
# Test with access token
curl -X POST https://project.iith.ac.in/bheri/api/google_login/ \
  -H "Content-Type: application/json" \
  -d '{"access_token": "ya29.a0AQQ_BDR..."}'
```

---

## 🔐 Security Considerations

### 1. Always Validate Tokens
```python
# ❌ DON'T: Trust tokens without validation
user_email = request.data.get('email')  # Can be faked!

# ✅ DO: Validate with Google
user_info = validate_google_access_token(token)
```

### 2. Check Email Verification
```python
if not user_info.get('email_verified'):
    return Response({'error': 'Email not verified'}, status=400)
```

### 3. Set Token Expiry
```python
# Your JWT tokens should have reasonable expiry
access_token_lifetime = timedelta(hours=1)
refresh_token_lifetime = timedelta(days=7)
```

### 4. Rate Limiting
```python
# Add rate limiting to prevent abuse
from rest_framework.throttling import AnonRateThrottle

class GoogleLoginThrottle(AnonRateThrottle):
    rate = '10/hour'
```

---

## 🐛 Debugging

### Check What Token Type You're Receiving

```python
@api_view(['POST'])
def google_login(request):
    token = request.data.get('access_token')
    
    print(f"Received token: {token[:50]}...")  # Print first 50 chars
    print(f"Token length: {len(token)}")
    
    # ID tokens are JWTs (3 parts separated by dots)
    if token.count('.') == 2:
        print("This looks like an ID token (JWT)")
    else:
        print("This looks like an access token (OAuth)")
    
    # Continue with validation...
```

### Log Token Validation Response

```python
def validate_google_access_token(access_token):
    response = requests.get(
        'https://www.googleapis.com/oauth2/v3/tokeninfo',
        params={'access_token': access_token}
    )
    
    print(f"Google response status: {response.status_code}")
    print(f"Google response body: {response.json()}")
    
    # Continue...
```

---

## 📊 Expected Flow

### Web Client Flow
```
1. User clicks "Sign in with Google" in Flutter web
2. Google popup opens
3. User selects account
4. Google returns access_token (ya29...)
5. Flutter sends: POST /api/google_login/ {"access_token": "ya29..."}
6. Backend validates with Google tokeninfo API
7. Backend creates/updates user
8. Backend returns JWT tokens
9. Flutter stores JWT and user is logged in ✅
```

### Mobile Client Flow
```
1. User clicks "Sign in with Google" in Flutter mobile
2. Native Google Sign-In
3. Google returns id_token (eyJ...)
4. Flutter sends: POST /api/google_login/ {"access_token": "eyJ..."}
5. Backend validates JWT signature
6. Backend creates/updates user
7. Backend returns JWT tokens
8. Flutter stores JWT and user is logged in ✅
```

---

## 🎯 Quick Fix for Testing

If you want to quickly test, add this temporary debug endpoint:

```python
@api_view(['POST'])
def debug_google_token(request):
    """
    Debug endpoint to see what's being sent and what Google returns.
    REMOVE THIS IN PRODUCTION!
    """
    token = request.data.get('access_token')
    
    # Try to get info from Google
    response = requests.get(
        'https://www.googleapis.com/oauth2/v3/tokeninfo',
        params={'access_token': token}
    )
    
    return Response({
        'received_token_length': len(token) if token else 0,
        'google_response_status': response.status_code,
        'google_response_body': response.json() if response.status_code == 200 else response.text,
    })
```

---

## ✅ Checklist for Backend Team

- [ ] Install `google-auth` package
- [ ] Update `/api/google_login/` to validate access tokens
- [ ] Test with actual access token from web client
- [ ] Ensure CORS allows your web domain
- [ ] Add proper error messages
- [ ] Test with both web and mobile clients
- [ ] Remove debug endpoints before production
- [ ] Add rate limiting
- [ ] Log authentication attempts for security

---

## 📞 Common Issues

### Issue: "Invalid token" for valid tokens
**Cause**: Not validating with Google API  
**Fix**: Call `https://www.googleapis.com/oauth2/v3/tokeninfo`

### Issue: CORS errors
**Cause**: CORS not configured for web domain  
**Fix**: Add to CORS_ALLOWED_ORIGINS in settings.py

### Issue: Token expired
**Cause**: Access tokens expire in ~1 hour  
**Fix**: This is normal, handle gracefully with refresh flow

---

## 🚀 Deployment Notes

### Environment Variables

```python
# settings.py
GOOGLE_OAUTH_CLIENT_ID = os.environ.get('GOOGLE_OAUTH_CLIENT_ID')

# Use in validation
def validate_google_id_token(id_token):
    id_info = google_id_token.verify_oauth2_token(
        id_token,
        google_requests.Request(),
        GOOGLE_OAUTH_CLIENT_ID  # Verify it's for your app
    )
```

### Production Checklist

- [ ] Use HTTPS only
- [ ] Set proper CORS headers
- [ ] Enable rate limiting
- [ ] Log authentication events
- [ ] Monitor for suspicious activity
- [ ] Have token refresh flow
- [ ] Clear error messages (but not too revealing)

---

## Summary

**The Fix Needed**: Your backend must call Google's API to validate the access token:

```python
response = requests.get(
    'https://www.googleapis.com/oauth2/v3/tokeninfo',
    params={'access_token': access_token}
)
```

**Why**: Web clients can't get ID tokens reliably, so they send access tokens which must be validated server-side.

**Result**: After this fix, both web and mobile login will work seamlessly! ✅







