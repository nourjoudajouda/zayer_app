# Auth API Contract

توثيق تعاقد الـ API للمصادقة - يجب أن تطابق الشاشات والحقول المُرحلة ما يلي.

## POST /api/auth/register

**الحقول المقبولة فقط (snake_case):**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `full_name` | string | نعم | الاسم الكامل |
| `phone` | string | نعم | رقم الهاتف بالتنسيق E.164 (مع مفتاح الدولة، مثال: 966512345678) |
| `password` | string | نعم | كلمة المرور |
| `password_confirmation` | string | نعم | تأكيد كلمة المرور |
| `country_id` | string/int | لا | معرف الدولة من GET /api/countries |
| `city_id` | string/int | لا | معرف المدينة من GET /api/cities |

**ملاحظة:** إذا كان الـ API لا يقبل `country_id` أو `city_id`، لن نُرسلهما.

---

## POST /api/auth/login

| Field | Type | Required |
|-------|------|----------|
| `phone` | string | نعم | E.164 (نفس التنسيق المستخدم عند التسجيل) |
| `password` | string | نعم |
| `fcm_token` | string | لا | اختياري للـ push notifications |
| `device_type` | string | لا | android / web |

---

## POST /api/auth/login-otp

طلب رمز OTP لتسجيل الدخول بدون كلمة مرور (يجب أن يكون الحساب مسجّلاً مسبقاً).

| Field | Type | Required |
|-------|------|----------|
| `phone` | string | نعم | E.164 |

**استجابة ناجحة (200):** مثل forgot-password (`message`, `phone`؛ وفي وضع التطوير قد يُرفق `otp`).

**أخطاء شائعة:** `404` إذا لم يكن الرقم مسجّلاً (`Phone not registered`).

---

## POST /api/auth/verify-otp

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `phone` | string | نعم | E.164 |
| `code` | string | نعم | رمز OTP (6 أرقام) |
| `mode` | string | نعم | `signup` أو `reset` أو `login` |
| `password` | string | شرطي | عند mode=reset |
| `password_confirmation` | string | شرطي | عند mode=reset |
| `fcm_token` | string | لا | اختياري |
| `device_type` | string | لا | android / web |

---

## POST /api/auth/forgot-password

| Field | Type | Required |
|-------|------|----------|
| `phone` | string | نعم | E.164 |

---

## POST /api/auth/logout

لا يحتاج body، يستخدم Bearer token.

---

## وضع التطوير (Dev OTP)

عند تشغيل التطبيق في وضع debug (`flutter run` أو `flutter run --debug`) والتطبيق لا يستخدم خدمة إرسال SMS حقيقية، يمكن للـ API إرجاع OTP في الاستجابة:

- **register (201):** أضف `otp` أو `code` في JSON للاستجابة.
- **forgot-password (200):** أضف `otp` أو `code` في JSON للاستجابة.
- **login-otp (200):** أضف `otp` أو `code` في JSON للاستجابة.

مثال استجابة:
```json
{
  "phone": "966512345678",
  "user_id": 1,
  "otp": "123456"
}
```

التطبيق يعرض OTP على شاشة التحقق ويُعبّئ الحقول تلقائياً، مما يتيح الاختبار بدون SMS.
