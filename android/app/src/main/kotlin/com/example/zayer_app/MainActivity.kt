package com.zayer.app

import io.flutter.embedding.android.FlutterFragmentActivity

/// flutter_stripe requires [FlutterFragmentActivity] so Stripe Android SDK views
/// (CardField, PaymentSheet, 3DS) receive correct fragment lifecycle and input focus.
class MainActivity : FlutterFragmentActivity()
