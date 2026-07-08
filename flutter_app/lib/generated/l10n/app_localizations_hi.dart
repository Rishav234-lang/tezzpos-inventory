// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'TezzPOS';

  @override
  String get appName => 'TezzPOS';

  @override
  String get tagline => 'प्रबंधित करें। ट्रैक करें। विश्लेषण करें। बढ़ें।';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get profileDetails => 'प्रोफ़ाइल विवरण';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get name => 'नाम';

  @override
  String get email => 'ईमेल';

  @override
  String get company => 'कंपनी';

  @override
  String get role => 'भूमिका';

  @override
  String get license => 'लाइसेंस';

  @override
  String get licenseAndSubscription => 'लाइसेंस और सब्सक्रिप्शन';

  @override
  String get accountStatus => 'खाता स्थिति';

  @override
  String get validTill => 'वैध तिथि';

  @override
  String get subscription => 'सब्सक्रिप्शन';

  @override
  String get currentSubscriptionData => 'वर्तमान सब्सक्रिप्शन विवरण';

  @override
  String get subscriptionId => 'सब्सक्रिप्शन आईडी';

  @override
  String get plan => 'प्लान';

  @override
  String get billingCycle => 'बिलिंग चक्र';

  @override
  String get autoRenew => 'ऑटो नवीनीकरण';

  @override
  String get viewSubscriptionDetails => 'सब्सक्रिप्शन विवरण देखें';

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String get companyNotAvailable => 'कंपनी उपलब्ध नहीं';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get enabled => 'सक्षम';

  @override
  String get disabled => 'अक्षम';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get marathi => 'मराठी';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get close => 'बंद करें';

  @override
  String get continueText => 'जारी रखें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get skip => 'छोड़ें';

  @override
  String get onboardingTitle1 => 'स्मार्ट इन्वेंटरी';

  @override
  String get onboardingDesc1 =>
      'प्रत्येक उत्पाद को बैच-स्तरीय सटीकता के साथ ट्रैक करें। FIFO स्टॉक प्रबंधन यह सुनिश्चित करता है कि आप कभी भी एक्सपायरी डेट या स्टॉक स्तरों को न भूलें।';

  @override
  String get onboardingTitle2 => 'GST बिलिंग';

  @override
  String get onboardingDesc2 =>
      'स्वचालित CGST, SGST और IGST के साथ GST-अनुपालित चालान बनाएं। तुरंत PDF निर्यात करें और पूरे साल टैक्स-तैयार रहें।';

  @override
  String get onboardingTitle3 => 'अपना व्यवसाय बढ़ाएं';

  @override
  String get onboardingDesc3 =>
      'रीयल-टाइम डैशबोर्ड, विक्रेता और ग्राहक अंतर्दृष्टि, लाभ रिपोर्ट और कम स्टॉक अलर्ट — स्मार्ट रूप से स्केल करने के लिए सब कुछ।';

  @override
  String get submit => 'जमा करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get search => 'खोजें';

  @override
  String get noResults => 'कोई परिणाम नहीं मिला';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफल';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get back => 'पीछे';

  @override
  String get next => 'अगला';

  @override
  String get done => 'हो गया';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get ok => 'ठीक है';

  @override
  String get welcome => 'स्वागत है';

  @override
  String welcomeToApp(Object appName) {
    return '$appName में आपका स्वागत है';
  }

  @override
  String get selectRoleToContinue => 'जारी रखने के लिए अपनी भूमिका चुनें';

  @override
  String get login => 'लॉगिन';

  @override
  String get companyLogin => 'कंपनी लॉगिन';

  @override
  String get companyLoginSubtitle =>
      'अपनी दुकान की इन्वेंटरी और बिलिंग प्रबंधित करने के लिए साइन इन करें।';

  @override
  String get superAdminLogin => 'सुपर एडमिन लॉगिन';

  @override
  String get superAdminLoginSubtitle => 'प्लेटफ़ॉर्म प्रशासन पहुंच।';

  @override
  String get adminEmailHint => 'admin@tezzpos.com';

  @override
  String get loginAsCompanyOwner => 'कंपनी मालिक के रूप में लॉगिन करें';

  @override
  String get emailHint => 'owner@company.com';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get emailInvalid => 'वैध ईमेल दर्ज करें';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक है';

  @override
  String passwordMinLength(Object count) {
    return 'पासवर्ड कम से कम $count अक्षरों का होना चाहिए';
  }

  @override
  String get or => 'या';

  @override
  String get createNewAccount => 'नया खाता बनाएं';

  @override
  String get loginAsSuperAdmin => 'सुपर एडमिन के रूप में लॉगिन करें';

  @override
  String get register => 'रजिस्टर';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get dontHaveAccount => 'खाता नहीं है?';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get signUp => 'साइन अप';

  @override
  String get signIn => 'साइन इन';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get home => 'होम';

  @override
  String get products => 'उत्पाद';

  @override
  String get sales => 'बिक्री';

  @override
  String get purchases => 'खरीद';

  @override
  String get inventory => 'इन्वेंटरी';

  @override
  String get reports => 'रिपोर्ट्स';

  @override
  String get customers => 'ग्राहक';

  @override
  String get vendors => 'विक्रेता';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get about => 'के बारे में';

  @override
  String get help => 'सहायता';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get version => 'संस्करण';

  @override
  String get logoutConfirmation =>
      'क्या आप निश्चित रूप से लॉगआउट करना चाहते हैं?';

  @override
  String get subscriptionExpired => 'सब्सक्रिप्शन समाप्त हो गया';

  @override
  String get subscriptionExpiredMessage =>
      'आपका सब्सक्रिप्शन समाप्त हो गया है। TezzPOS का उपयोग जारी रखने के लिए अभी नवीनीकरण करें।';

  @override
  String get renewSubscription => 'सब्सक्रिप्शन नवीनीकरण करें';

  @override
  String get enableAutoPay => 'ऑटो-पे सक्षम करें';

  @override
  String get autoPayAuthorizedSuccessfully =>
      'ऑटो-पे सफलतापूर्वक अधिकृत हो गया!';

  @override
  String get autoPaySetupOnlyMobile =>
      'ऑटो-पे सेटअप केवल मोबाइल ऐप पर उपलब्ध है।';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get needHelp => 'मदद चाहिए?';

  @override
  String get currentPlan => 'वर्तमान प्लान';

  @override
  String get unknownPlan => 'अज्ञात प्लान';

  @override
  String billingLabel(Object cycle) {
    return 'बिलिंग: $cycle';
  }

  @override
  String get autoRenewEnabled => 'ऑटो-नवीनीकरण सक्षम';

  @override
  String subscriptionEndedOn(Object date) {
    return 'आपकी सदस्यता $date को समाप्त हो गई। TezzPOS का उपयोग जारी रखने के लिए अभी नवीनीकरण करें।';
  }

  @override
  String oneDayOverdue(Object days) {
    return '$days दिन बकाया';
  }

  @override
  String daysOverdue(Object days) {
    return '$days दिन बकाया';
  }

  @override
  String get paymentVerificationFailed =>
      'भुगतान सत्यापन विफल। कृपया सहायता से संपर्क करें।';

  @override
  String get noSubscriptionPlanFound =>
      'कोई सदस्यता प्लान नहीं मिला। कृपया सहायता से संपर्क करें।';

  @override
  String get failedToCreatePaymentOrder =>
      'भुगतान ऑर्डर बनाने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get couldNotOpenPaymentPage => 'भुगतान पेज नहीं खोला जा सका।';

  @override
  String get failedToCreateAutoPaySubscription =>
      'ऑटो-पे सदस्यता बनाने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get oneTimePayment => 'एकमुश्त भुगतान';

  @override
  String get monthly => 'मासिक';

  @override
  String get yearly => 'वार्षिक';

  @override
  String get paymentSuccessful =>
      'भुगतान सफल! पुनर्निर्देशित किया जा रहा है...';

  @override
  String paymentFailed(Object message) {
    return 'भुगतान विफल: $message';
  }

  @override
  String get paymentCancelled => 'भुगतान रद्द कर दिया गया था।';

  @override
  String get noSubscriptionData => 'कोई सब्सक्रिप्शन डेटा नहीं';

  @override
  String get trial => 'ट्रायल';

  @override
  String get expired => 'समाप्त';

  @override
  String get suspended => 'निलंबित';

  @override
  String get pending => 'लंबित';

  @override
  String get approved => 'स्वीकृत';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get owner => 'मालिक';

  @override
  String get superAdmin => 'सुपर एडमिन';

  @override
  String get user => 'उपयोगकर्ता';

  @override
  String get companyOwner => 'कंपनी मालिक';

  @override
  String get companyOwnerDescription =>
      'अपनी दुकान के लिए इन्वेंटरी, बिक्री, खरीद और बिलिंग प्रबंधित करें।';

  @override
  String get superAdminDescription =>
      'कंपनियों, प्लानों, सब्सक्रिप्शन और प्लेटफ़ॉर्म एनालिटिक्स प्रबंधित करें।';

  @override
  String get totalSales => 'कुल बिक्री';

  @override
  String get totalPurchases => 'कुल खरीद';

  @override
  String get totalProducts => 'कुल उत्पाद';

  @override
  String get lowStock => 'कम स्टॉक';

  @override
  String get recentTransactions => 'हाल के लेनदेन';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get date => 'तारीख';

  @override
  String get amount => 'राशि';

  @override
  String get status => 'स्थिति';

  @override
  String get actions => 'कार्रवाइयां';

  @override
  String get category => 'श्रेणी';

  @override
  String get price => 'कीमत';

  @override
  String get quantity => 'मात्रा';

  @override
  String get stock => 'स्टॉक';

  @override
  String get addNew => 'नया जोड़ें';

  @override
  String get create => 'बनाएं';

  @override
  String get update => 'अपडेट करें';

  @override
  String get remove => 'हटाएं';

  @override
  String get areYouSure => 'क्या आप निश्चित हैं?';

  @override
  String get thisActionCannotBeUndone =>
      'इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get languageChanged => 'भाषा सफलतापूर्वक बदली गई';
}
