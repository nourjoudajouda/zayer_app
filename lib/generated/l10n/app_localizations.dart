import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Eshterely'**
  String get appTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop globally, delivered locally'**
  String get splashSubtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Shop from Global Stores'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Description.
  ///
  /// In en, this message translates to:
  /// **'Access millions of products from the world\'s best markets directly through Eshterely.'**
  String get onboardingPage1Description;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Combine & Save'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Description.
  ///
  /// In en, this message translates to:
  /// **'We group your purchases by origin country to minimize shipping costs and maximize your savings.'**
  String get onboardingPage2Description;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Transparent Tracking'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Description.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees. Track your consolidated shipments from the warehouse to your doorstep in real-time.'**
  String get onboardingPage3Description;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @joinZayer.
  ///
  /// In en, this message translates to:
  /// **'Join Eshterely'**
  String get joinZayer;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start shopping globally.'**
  String get createAccountSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+1 234 567 8900'**
  String get phoneNumberHint;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @haveReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get haveReferralCode;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @passwordReq8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordReq8Chars;

  /// No description provided for @passwordReqNumber.
  ///
  /// In en, this message translates to:
  /// **'Include a number'**
  String get passwordReqNumber;

  /// No description provided for @passwordReqSpecial.
  ///
  /// In en, this message translates to:
  /// **'Include a special character'**
  String get passwordReqSpecial;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Login with OTP instead'**
  String get loginWithOtp;

  /// No description provided for @noPasswordNeeded.
  ///
  /// In en, this message translates to:
  /// **'No password needed'**
  String get noPasswordNeeded;

  /// No description provided for @loginOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone registered on your account. We will send a login code by SMS.'**
  String get loginOtpSubtitle;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orContinueWith;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @marketsStores.
  ///
  /// In en, this message translates to:
  /// **'Markets / Stores'**
  String get marketsStores;

  /// No description provided for @amazonUs.
  ///
  /// In en, this message translates to:
  /// **'Amazon US'**
  String get amazonUs;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone Number'**
  String get verifyPhoneNumber;

  /// No description provided for @weSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to'**
  String get weSentCodeTo;

  /// No description provided for @enterCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent'**
  String get enterCodeSent;

  /// No description provided for @checkMessages.
  ///
  /// In en, this message translates to:
  /// **'Check your messages for the 6-digit code.'**
  String get checkMessages;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendIn;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @termsText.
  ///
  /// In en, this message translates to:
  /// **'By verifying, you agree to our Terms of Service and Privacy Policy.'**
  String get termsText;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP code'**
  String get pleaseEnterOtp;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit code'**
  String get enter6DigitCode;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @pleaseSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectCountry;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get sendResetCode;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetCodeSentNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a reset code to your phone.'**
  String get resetCodeSentNote;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @shopOnAmazon.
  ///
  /// In en, this message translates to:
  /// **'Shop on Amazon'**
  String get shopOnAmazon;

  /// No description provided for @shopOnStore.
  ///
  /// In en, this message translates to:
  /// **'Shop on {store}'**
  String shopOnStore(Object store);

  /// No description provided for @pasteProductLink.
  ///
  /// In en, this message translates to:
  /// **'Paste product link'**
  String get pasteProductLink;

  /// No description provided for @whatYouCanShop.
  ///
  /// In en, this message translates to:
  /// **'What you can shop'**
  String get whatYouCanShop;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String helloUser(Object name);

  /// No description provided for @welcomeBackCaps.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBackCaps;

  /// No description provided for @searchStoresOrItems.
  ///
  /// In en, this message translates to:
  /// **'Search stores or items…'**
  String get searchStoresOrItems;

  /// No description provided for @flashSale.
  ///
  /// In en, this message translates to:
  /// **'FLASH SALE'**
  String get flashSale;

  /// No description provided for @upTo40Off.
  ///
  /// In en, this message translates to:
  /// **'Up to 40% off on US Premium Brands'**
  String get upTo40Off;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get shopNow;

  /// No description provided for @globalMarkets.
  ///
  /// In en, this message translates to:
  /// **'Global Markets'**
  String get globalMarkets;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @storesCount.
  ///
  /// In en, this message translates to:
  /// **'{count}+ stores'**
  String storesCount(Object count);

  /// No description provided for @consolidationSavings.
  ///
  /// In en, this message translates to:
  /// **'Consolidation Savings'**
  String get consolidationSavings;

  /// No description provided for @consolidationSavingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine orders from same region to save on shipping'**
  String get consolidationSavingsSubtitle;

  /// No description provided for @popularStores.
  ///
  /// In en, this message translates to:
  /// **'Popular Stores'**
  String get popularStores;

  /// No description provided for @officialStore.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL STORE'**
  String get officialStore;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'SECURE'**
  String get secure;

  /// No description provided for @findProducts.
  ///
  /// In en, this message translates to:
  /// **'Find Products'**
  String get findProducts;

  /// No description provided for @findProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse millions of products from global stores'**
  String get findProductsDesc;

  /// No description provided for @addToZayerCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Eshterely Cart'**
  String get addToZayerCart;

  /// No description provided for @addToZayerCartDesc.
  ///
  /// In en, this message translates to:
  /// **'Add items to your Eshterely cart for consolidation'**
  String get addToZayerCartDesc;

  /// No description provided for @globalDelivery.
  ///
  /// In en, this message translates to:
  /// **'Global Delivery'**
  String get globalDelivery;

  /// No description provided for @globalDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'We ship to your doorstep from our warehouses'**
  String get globalDeliveryDesc;

  /// No description provided for @consolidationBenefits.
  ///
  /// In en, this message translates to:
  /// **'CONSOLIDATION BENEFITS'**
  String get consolidationBenefits;

  /// No description provided for @saveUpTo70.
  ///
  /// In en, this message translates to:
  /// **'Save up to 70% on shipping'**
  String get saveUpTo70;

  /// No description provided for @profileAndCompliance.
  ///
  /// In en, this message translates to:
  /// **'Profile & Compliance'**
  String get profileAndCompliance;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'ACTION REQUIRED'**
  String get actionRequired;

  /// No description provided for @uploadNewGovernmentId.
  ///
  /// In en, this message translates to:
  /// **'Upload New Government ID'**
  String get uploadNewGovernmentId;

  /// No description provided for @whyIsThisRequired.
  ///
  /// In en, this message translates to:
  /// **'Why is this required?'**
  String get whyIsThisRequired;

  /// No description provided for @fullLegalName.
  ///
  /// In en, this message translates to:
  /// **'Full Legal Name'**
  String get fullLegalName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @primaryShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Primary Shipping Address'**
  String get primaryShippingAddress;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get defaultBadge;

  /// No description provided for @verifiedForInternational.
  ///
  /// In en, this message translates to:
  /// **'Verified for international shipping'**
  String get verifiedForInternational;

  /// No description provided for @lastVerified.
  ///
  /// In en, this message translates to:
  /// **'Last verified'**
  String get lastVerified;

  /// No description provided for @infoHintAddress.
  ///
  /// In en, this message translates to:
  /// **'Add or update your default shipping address for faster checkout'**
  String get infoHintAddress;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @checkConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check network and retry.'**
  String get checkConnectionAndRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @defaultAddressChangeCartReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note: If you change your default delivery address, all items in your cart will be sent for admin review again.'**
  String get defaultAddressChangeCartReviewNote;

  /// No description provided for @shippingReviewNoteFull.
  ///
  /// In en, this message translates to:
  /// **'The shipping cost shown is an estimate only and will be reviewed and confirmed by admin after inspecting the product and its specifications.'**
  String get shippingReviewNoteFull;

  /// No description provided for @shippingReviewNoteShort.
  ///
  /// In en, this message translates to:
  /// **'Note: Shipping cost is subject to admin review before final confirmation.'**
  String get shippingReviewNoteShort;

  /// No description provided for @exactMeasurementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exact measurements'**
  String get exactMeasurementsLabel;

  /// No description provided for @estimatedShippingLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated shipping'**
  String get estimatedShippingLabel;

  /// No description provided for @estimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotalLabel;

  /// No description provided for @shippingFallbackPrefix.
  ///
  /// In en, this message translates to:
  /// **'Estimated shipping based on fallback measurements. '**
  String get shippingFallbackPrefix;

  /// No description provided for @measurementsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Measurements not available from store. Shipping is estimated and subject to review.'**
  String get measurementsNotAvailable;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @dimensionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensionsLabel;

  /// No description provided for @shippingNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping note'**
  String get shippingNoteLabel;

  /// No description provided for @importProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your product…'**
  String get importProgressTitle;

  /// No description provided for @importProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll fetch product details and calculate shipping before confirmation.'**
  String get importProgressSubtitle;

  /// No description provided for @importProgressKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open…'**
  String get importProgressKeepOpen;

  /// No description provided for @importProgressReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for confirmation'**
  String get importProgressReady;

  /// No description provided for @importProgressFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importProgressFailed;

  /// No description provided for @importProgressTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get importProgressTryAgain;

  /// No description provided for @importProgressStepImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing product'**
  String get importProgressStepImporting;

  /// No description provided for @importProgressStepReading.
  ///
  /// In en, this message translates to:
  /// **'Reading product details'**
  String get importProgressStepReading;

  /// No description provided for @importProgressStepShipping.
  ///
  /// In en, this message translates to:
  /// **'Calculating shipping'**
  String get importProgressStepShipping;

  /// No description provided for @importProgressStepPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing confirmation'**
  String get importProgressStepPreparing;

  /// No description provided for @importPasteStepDetectingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Detecting measurements'**
  String get importPasteStepDetectingMeasurements;

  /// No description provided for @reviewAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Review & Add'**
  String get reviewAndAdd;

  /// No description provided for @collectingProductInformation.
  ///
  /// In en, this message translates to:
  /// **'Collecting product information…'**
  String get collectingProductInformation;

  /// No description provided for @importProgressAddingToCart.
  ///
  /// In en, this message translates to:
  /// **'Adding the product to your cart'**
  String get importProgressAddingToCart;

  /// No description provided for @importProgressStepExtractDetails.
  ///
  /// In en, this message translates to:
  /// **'Extracting product details'**
  String get importProgressStepExtractDetails;

  /// No description provided for @importProgressStepCustomsCompliance.
  ///
  /// In en, this message translates to:
  /// **'Checking customs compliance'**
  String get importProgressStepCustomsCompliance;

  /// No description provided for @importProgressStepShippingCosts.
  ///
  /// In en, this message translates to:
  /// **'Calculating shipping costs'**
  String get importProgressStepShippingCosts;

  /// No description provided for @importProgressStepCustomsDuties.
  ///
  /// In en, this message translates to:
  /// **'Calculating customs duties'**
  String get importProgressStepCustomsDuties;

  /// No description provided for @importProgressStepShippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Identifying shipping method'**
  String get importProgressStepShippingMethod;

  /// No description provided for @importProgressStepFinishingCart.
  ///
  /// In en, this message translates to:
  /// **'Finishing adding to cart'**
  String get importProgressStepFinishingCart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
