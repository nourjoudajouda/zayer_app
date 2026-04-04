// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'اشترلي';

  @override
  String get splashSubtitle => 'تسوق عالميًا، توصيل محلي';

  @override
  String get skip => 'تخطي';

  @override
  String get onboardingPage1Title => 'تسوق من متاجر العالم';

  @override
  String get onboardingPage1Description =>
      'الوصول إلى ملايين المنتجات من أفضل أسواق العالم مباشرة عبر اشترلي.';

  @override
  String get onboardingPage2Title => 'اجمع ووفر';

  @override
  String get onboardingPage2Description =>
      'نجمع مشترياتك حسب دولة المنشأ لتقليل تكاليف الشحن وزيادة توفيرك.';

  @override
  String get onboardingPage3Title => 'تتبع شفاف';

  @override
  String get onboardingPage3Description =>
      'بدون رسوم خفية. تتبع شحناتك المجمعة من المستودع إلى عتبة بابك في الوقت الفعلي.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get joinZayer => 'انضم إلى اشترلي';

  @override
  String get createAccountSubtitle => 'أنشئ حسابك لبدء التسوق عالميًا.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => '+966 5XX XXX XXXX';

  @override
  String get country => 'الدولة';

  @override
  String get city => 'المدينة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get haveReferralCode => 'لديك رمز إحالة؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get passwordReq8Chars => '8 أحرف على الأقل';

  @override
  String get passwordReqNumber => 'يتضمن رقماً';

  @override
  String get passwordReqSpecial => 'يتضمن رمزاً خاصاً';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get loginWithOtp => 'تسجيل الدخول برمز OTP بدلاً من ذلك';

  @override
  String get noPasswordNeeded => 'لا تحتاج كلمة مرور';

  @override
  String get loginOtpSubtitle =>
      'أدخل رقم الهاتف المسجّل في حسابك. سنرسل رمز تسجيل الدخول عبر الرسائل.';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get apple => 'أبل';

  @override
  String get google => 'جوجل';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get home => 'الرئيسية';

  @override
  String get marketsStores => 'الأسواق / المتاجر';

  @override
  String get amazonUs => 'أمازون أمريكا';

  @override
  String get verifyOtp => 'تحقق من الرمز';

  @override
  String get verifyPhoneNumber => 'تحقق من رقم الهاتف';

  @override
  String get weSentCodeTo => 'أرسلنا رمزاً من 6 أرقام إلى';

  @override
  String get enterCodeSent => 'أدخل الرمز الذي أرسلناه';

  @override
  String get checkMessages =>
      'تحقق من رسائلك للحصول على الرمز المكون من 6 أرقام.';

  @override
  String get otpCode => 'رمز OTP';

  @override
  String get verify => 'تحقق';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get resendIn => 'إعادة الإرسال خلال';

  @override
  String get edit => 'تعديل';

  @override
  String get termsText => 'بالتحقق، أنت توافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get sendOtp => 'إرسال الرمز';

  @override
  String get store => 'المتجر';

  @override
  String get pleaseEnterPhone => 'يرجى إدخال رقم هاتفك';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get pleaseEnterOtp => 'يرجى إدخال رمز OTP';

  @override
  String get enter6DigitCode => 'أدخل رمزاً من 6 أرقام';

  @override
  String get pleaseEnterFullName => 'يرجى إدخال اسمك الكامل';

  @override
  String get pleaseSelectCountry => 'يرجى اختيار الدولة';

  @override
  String get pleaseSelectCity => 'يرجى اختيار المدينة';

  @override
  String get sendResetCode => 'إرسال رمز إعادة التعيين';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get resetCodeSentNote => 'سنرسل رمز إعادة التعيين إلى هاتفك.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get shopOnAmazon => 'تسوق على أمازون';

  @override
  String shopOnStore(Object store) {
    return 'تسوق على $store';
  }

  @override
  String get pasteProductLink => 'لصق رابط المنتج';

  @override
  String get whatYouCanShop => 'ما يمكنك تسوقه';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get securitySettings => 'إعدادات الأمان';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get identityVerification => 'التحقق من الهوية';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get address => 'العنوان';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get comingSoon => 'قريباً';

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
      'لا يوجد اتصال. تحقق من الشبكة وحاول مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get defaultAddressChangeCartReviewNote =>
      'ملاحظة: عند تغيير عنوان التوصيل الافتراضي، تُعاد جميع عناصر السلة إلى مراجعة الإدارة.';

  @override
  String get shippingReviewNoteFull =>
      'سعر الشحن المعروض حاليًا تقديري فقط، وسيتم مراجعته واعتماده من الإدارة بعد فحص المنتج والمواصفات.';

  @override
  String get shippingReviewNoteShort =>
      'ملاحظة: سعر الشحن سيخضع لمراجعة الإدارة قبل الاعتماد النهائي.';

  @override
  String get exactMeasurementsLabel => 'قياسات دقيقة';

  @override
  String get estimatedShippingLabel => 'شحن تقديري';

  @override
  String get estimatedTotalLabel => 'الإجمالي التقديري';

  @override
  String get shippingFallbackPrefix => 'شحن تقديري بناءً على قياسات افتراضية. ';

  @override
  String get measurementsNotAvailable =>
      'المقاسات غير متاحة من المتجر. الشحن تقديري ويخضع للمراجعة.';

  @override
  String get weightLabel => 'الوزن';

  @override
  String get dimensionsLabel => 'الأبعاد';

  @override
  String get shippingNoteLabel => 'ملاحظة الشحن';

  @override
  String get importProgressTitle => 'جارٍ تجهيز المنتج…';

  @override
  String get importProgressSubtitle =>
      'سنقوم بجلب تفاصيل المنتج وحساب الشحن قبل التأكيد.';

  @override
  String get importProgressKeepOpen => 'اترك هذه الشاشة مفتوحة…';

  @override
  String get importProgressReady => 'جاهز للتأكيد';

  @override
  String get importProgressFailed => 'فشل الاستيراد';

  @override
  String get importProgressTryAgain => 'تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get importProgressStepImporting => 'جارٍ استيراد المنتج';

  @override
  String get importProgressStepReading => 'جارٍ قراءة تفاصيل المنتج';

  @override
  String get importProgressStepShipping => 'جارٍ حساب الشحن';

  @override
  String get importProgressStepPreparing => 'جارٍ تجهيز التأكيد';

  @override
  String get importPasteStepDetectingMeasurements => 'جارٍ اكتشاف المقاسات';

  @override
  String get reviewAndAdd => 'مراجعة ثم إضافة';

  @override
  String get collectingProductInformation => 'جارٍ جمع معلومات المنتج…';

  @override
  String get importProgressAddingToCart => 'جارٍ إضافة المنتج إلى سلتك';

  @override
  String get importProgressStepExtractDetails => 'استخراج تفاصيل المنتج';

  @override
  String get importProgressStepCustomsCompliance =>
      'التحقق من الامتثال الجمركي';

  @override
  String get importProgressStepShippingCosts => 'حساب تكاليف الشحن';

  @override
  String get importProgressStepCustomsDuties => 'حساب الرسوم الجمركية';

  @override
  String get importProgressStepShippingMethod => 'تحديد طريقة الشحن';

  @override
  String get importProgressStepFinishingCart => 'إنهاء الإضافة إلى السلة';
}
