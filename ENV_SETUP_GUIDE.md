# Environment Setup Guide 🔐

This guide will help you set up your environment variables for the Frobster User app.

## 📁 File Location

The environment file is located at: `lib/.env.dart`

**⚠️ IMPORTANT:** This file is ignored by Git (`.gitignore`) to protect your sensitive API keys.

---

## 🚀 Quick Setup

### Step 1: Locate the File
Open `lib/.env.dart` in your editor

### Step 2: Replace Placeholders
Replace all `'your-...-here'` placeholders with your actual API keys

### Step 3: Save and Run
Save the file and run your app with `flutter run`

---

## 🔑 Getting API Keys

### 1. PayPal
- Visit: https://developer.paypal.com/
- Create an app in the Developer Dashboard
- Copy **Client ID** and **Secret**
- Use **Sandbox** credentials for testing

### 2. Stripe
- Visit: https://dashboard.stripe.com/apikeys
- Get **Publishable Key** (pk_test_...)
- Get **Secret Key** (sk_test_...)
- Test keys start with `test`, live keys with `live`

### 3. Razorpay
- Visit: https://dashboard.razorpay.com/app/keys
- Copy **Key ID** and **Key Secret**
- Test keys start with `rzp_test_`, live with `rzp_live_`

### 4. Flutterwave
- Visit: https://dashboard.flutterwave.com/
- Get **Public Key**, **Secret Key**, and **Encryption Key**
- Test keys contain `TEST`, live keys contain `LIVE`

### 5. Paystack
- Visit: https://dashboard.paystack.com/#/settings/developer
- Copy **Public Key** and **Secret Key**
- Test keys start with `pk_test_` / `sk_test_`

### 6. Google Maps
- Visit: https://console.cloud.google.com/
- Create a project or select existing
- Enable these APIs:
  - Maps SDK for Android
  - Maps SDK for iOS
  - Places API
  - Geocoding API
- Create API key in **Credentials** section

### 7. Firebase
- Visit: https://console.firebase.google.com/
- Your main config is in:
  - `android/app/google-services.json` (Android)
  - `ios/Runner/GoogleService-Info.plist` (iOS)
- For Cloud Messaging, get **Server Key** from:
  - Project Settings → Cloud Messaging → Server Key

### 8. PhonePe
- Contact PhonePe for Business
- Get **Merchant ID**, **Salt Key**, and **Salt Index**

### 9. CinetPay
- Visit: https://cinetpay.com/
- Register as merchant
- Get **API Key** and **Site ID**

### 10. Airtel Money
- Visit: https://developers.airtel.africa/
- Register your application
- Get **Client ID** and **Client Secret**

---

## 🔄 Test vs Production

### For Development (Testing)
Use **test/sandbox** credentials:
- Safe to make mistakes
- No real money transactions
- Easier to test edge cases

```dart
const USE_TEST_CREDENTIALS = true;
const IS_DEVELOPMENT_MODE = true;
```

### For Production (Live)
Switch to **live** credentials:
- Real transactions
- Use with caution
- Monitor regularly

```dart
const USE_TEST_CREDENTIALS = false;
const IS_DEVELOPMENT_MODE = false;
```

---

## 🛡️ Security Best Practices

### ✅ DO:
- Keep `.env.dart` in `.gitignore`
- Use test credentials during development
- Rotate API keys regularly
- Use environment-specific keys (dev/staging/prod)
- Share credentials via secure password managers

### ❌ DON'T:
- Commit `.env.dart` to Git
- Share keys in screenshots or videos
- Use production keys in test environment
- Hard-code keys directly in code
- Share keys via email or messaging apps

---

## 🔧 Troubleshooting

### Error: "Undefined name 'PAYPAL_CLIENT_ID'"
**Solution:** Make sure `lib/.env.dart` exists and has the constant defined

### Error: "Target of URI doesn't exist"
**Solution:** Run `flutter pub get` to refresh the package cache

### Payment Not Working
**Solution:** 
1. Check if you're using correct credentials (test vs live)
2. Verify API key is active in the provider's dashboard
3. Check if payment method is enabled in your account
4. Look at console logs for specific error messages

### Google Maps Not Showing
**Solution:**
1. Verify API key is correct
2. Enable required APIs in Google Cloud Console
3. Check billing is enabled for Google Cloud project
4. Add API key to Android & iOS platform configs

---

## 📝 Environment File Structure

```dart
lib/
  .env.dart          ← Your API keys (NOT in Git)
  
android/
  app/
    google-services.json    ← Firebase config (Android)
    
ios/
  Runner/
    GoogleService-Info.plist  ← Firebase config (iOS)
```

---

## 👥 Team Setup

When a new team member joins:

1. They clone the repository
2. You share `.env.dart` securely (NOT via Git)
3. They place it in `lib/.env.dart`
4. They run `flutter pub get`
5. They can now run the app

---

## 📞 Need Help?

If you need help setting up API keys:
1. Check provider's documentation
2. Contact support team
3. Ask in your team chat

---

## 🎯 Checklist for Going Live

Before deploying to production:

- [ ] Replace ALL test credentials with live credentials
- [ ] Set `USE_TEST_CREDENTIALS = false`
- [ ] Set `IS_DEVELOPMENT_MODE = false`
- [ ] Test all payment gateways with small amounts
- [ ] Enable webhooks for payment providers
- [ ] Set up proper error logging
- [ ] Configure production Firebase project
- [ ] Test on real devices
- [ ] Set up monitoring and alerts

---

**Remember:** Keep your credentials safe and secure! 🔒

