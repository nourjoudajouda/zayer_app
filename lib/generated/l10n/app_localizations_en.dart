// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Eshterely';

  @override
  String get splashSubtitle => 'Shop globally, delivered locally';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingPage1Title => 'Shop from Global Stores';

  @override
  String get onboardingPage1Description =>
      'Access millions of products from the world\'s best markets directly through Eshterely.';

  @override
  String get onboardingPage2Title => 'Combine & Save';

  @override
  String get onboardingPage2Description =>
      'We group your purchases by origin country to minimize shipping costs and maximize your savings.';

  @override
  String get onboardingPage3Title => 'Transparent Tracking';

  @override
  String get onboardingPage3Description =>
      'No hidden fees. Track your consolidated shipments from the warehouse to your doorstep in real-time.';

  @override
  String get continueButton => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get joinZayer => 'Join Eshterely';

  @override
  String get createAccountSubtitle =>
      'Create your account to start shopping globally.';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => '+1 234 567 8900';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get haveReferralCode => 'Have a referral code?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get passwordReq8Chars => 'At least 8 characters';

  @override
  String get passwordReqNumber => 'Include a number';

  @override
  String get passwordReqSpecial => 'Include a special character';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get loginWithOtp => 'Login with OTP instead';

  @override
  String get noPasswordNeeded => 'No password needed';

  @override
  String get loginOtpSubtitle =>
      'Enter the phone registered on your account. We will send a login code by SMS.';

  @override
  String get orContinueWith => 'OR CONTINUE WITH';

  @override
  String get apple => 'Apple';

  @override
  String get google => 'Google';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get home => 'Home';

  @override
  String get marketsStores => 'Markets / Stores';

  @override
  String get amazonUs => 'Amazon US';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get verifyPhoneNumber => 'Verify Phone Number';

  @override
  String get weSentCodeTo => 'We\'ve sent a 6-digit code to';

  @override
  String get enterCodeSent => 'Enter the code we sent';

  @override
  String get checkMessages => 'Check your messages for the 6-digit code.';

  @override
  String get otpCode => 'OTP code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get resendIn => 'Resend in';

  @override
  String get edit => 'Edit';

  @override
  String get termsText =>
      'By verifying, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get store => 'Store';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseEnterOtp => 'Please enter the OTP code';

  @override
  String get enter6DigitCode => 'Enter a 6-digit code';

  @override
  String get pleaseEnterFullName => 'Please enter your full name';

  @override
  String get pleaseSelectCountry => 'Please select a country';

  @override
  String get pleaseSelectCity => 'Please select a city';

  @override
  String get sendResetCode => 'Send reset code';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetCodeSentNote => 'We\'ll send a reset code to your phone.';

  @override
  String get profile => 'Profile';

  @override
  String get shopOnAmazon => 'Shop on Amazon';

  @override
  String shopOnStore(Object store) {
    return 'Shop on $store';
  }

  @override
  String get pasteProductLink => 'Paste product link';

  @override
  String get whatYouCanShop => 'What you can shop';

  @override
  String get howItWorks => 'How it works';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get address => 'Address';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String helloUser(Object name) {
    return 'Hello, $name 👋';
  }

  @override
  String get welcomeBackCaps => 'WELCOME BACK';

  @override
  String get searchStoresOrItems => 'Search stores or items…';

  @override
  String get flashSale => 'FLASH SALE';

  @override
  String get upTo40Off => 'Up to 40% off on US Premium Brands';

  @override
  String get shopNow => 'Shop Now';

  @override
  String get globalMarkets => 'Global Markets';

  @override
  String get viewAll => 'View All';

  @override
  String storesCount(Object count) {
    return '$count+ stores';
  }

  @override
  String get consolidationSavings => 'Consolidation Savings';

  @override
  String get consolidationSavingsSubtitle =>
      'Combine orders from same region to save on shipping';

  @override
  String get popularStores => 'Popular Stores';

  @override
  String get officialStore => 'OFFICIAL STORE';

  @override
  String get secure => 'SECURE';

  @override
  String get findProducts => 'Find Products';

  @override
  String get findProductsDesc =>
      'Browse millions of products from global stores';

  @override
  String get addToZayerCart => 'Add to Eshterely Cart';

  @override
  String get addToZayerCartDesc =>
      'Add items to your Eshterely cart for consolidation';

  @override
  String get globalDelivery => 'Global Delivery';

  @override
  String get globalDeliveryDesc =>
      'We ship to your doorstep from our warehouses';

  @override
  String get consolidationBenefits => 'CONSOLIDATION BENEFITS';

  @override
  String get saveUpTo70 => 'Save up to 70% on shipping';

  @override
  String get profileAndCompliance => 'Profile & Compliance';

  @override
  String get actionRequired => 'ACTION REQUIRED';

  @override
  String get uploadNewGovernmentId => 'Upload New Government ID';

  @override
  String get whyIsThisRequired => 'Why is this required?';

  @override
  String get fullLegalName => 'Full Legal Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get primaryShippingAddress => 'Primary Shipping Address';

  @override
  String get defaultBadge => 'DEFAULT';

  @override
  String get verifiedForInternational => 'Verified for international shipping';

  @override
  String get lastVerified => 'Last verified';

  @override
  String get infoHintAddress =>
      'Add or update your default shipping address for faster checkout';

  @override
  String get import => 'Import';

  @override
  String get checkConnectionAndRetry =>
      'No connection. Check network and retry.';

  @override
  String get retry => 'Retry';

  @override
  String get defaultAddressChangeCartReviewNote =>
      'Note: If you change your default delivery address, all items in your cart will be sent for admin review again.';
}
