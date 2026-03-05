# تنفيذ api_base_url ووضع التطوير في لوحة Laravel

**لوحة الإدارة المعتمدة (أونلاين):** https://eshterely.duosparktech.com/public/admin

هذا الملف يوضح كيف تضيف في **مشروع اللوحة (Laravel)** حقلَي `api_base_url` و `development_mode` وتُرجعهما في استجابة الـ bootstrap. ملفات جاهزة للنسخ موجودة في مجلد المشروع: **`laravel_snippets/`** (انظر `laravel_snippets/README.md`).

---

## 1. قاعدة البيانات

### Migration

أنشئ migration لإضافة الحقلين إلى جدول التكوين (أو إنشاء جدول إن لم يكن موجوداً):

```bash
php artisan make:migration add_api_base_url_and_development_mode_to_app_config
```

مثال محتوى الـ migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('app_config', function (Blueprint $table) {
            $table->string('api_base_url')->nullable()->after('id');
            $table->boolean('development_mode')->default(false)->after('api_base_url');
        });
        // إذا لم يكن جدول app_config موجوداً، استخدم create بدلاً من table:
        // Schema::create('app_config', function (Blueprint $table) {
        //     $table->id();
        //     $table->string('api_base_url')->nullable();
        //     $table->boolean('development_mode')->default(false);
        //     $table->timestamps();
        // });
    }

    public function down(): void
    {
        Schema::table('app_config', function (Blueprint $table) {
            $table->dropColumn(['api_base_url', 'development_mode']);
        });
    }
};
```

ثم:

```bash
php artisan migrate
```

---

## 2. الموديل / القيم الافتراضية

إذا كنت تستخدم موديل أو مصفوفة إعدادات:

- **api_base_url**: نص (مثال: `https://api.zayer.com` أو `http://localhost:8000`). يمكن تركه فارغاً.
- **development_mode**: منطقي (true/false). عند true يظهر في التطبيق بانر "وضع التطوير" وشاشة التطوير.

---

## 3. إرجاع القيم في استجابة Bootstrap

في الـ Controller الذي يرجّع **GET /api/config/bootstrap** (أو الـ Resource)، أضف الحقلين إلى الـ JSON:

```php
// مثال في ConfigController أو BootstrapController

public function bootstrap()
{
    $config = [
        'theme' => $this->getTheme(),
        'splash' => $this->getSplash(),
        'onboarding' => $this->getOnboarding(),
        'markets' => $this->getMarkets(),
        'promo_banners' => $this->getPromoBanners(),
        // إضافة الحقلين من اللوحة:
        'api_base_url' => $this->getAppConfig('api_base_url'),   // من DB أو إعدادات
        'development_mode' => (bool) $this->getAppConfig('development_mode', false),
    ];

    return response()->json($config);
}

private function getAppConfig(string $key, $default = null)
{
    // مثال: من جدول app_config أو جدول settings
    return \DB::table('app_config')->value($key) ?? $default;
}
```

تأكد أن الـ endpoint يرجع **snake_case** كما في التطبيق: `api_base_url` و `development_mode`.

---

## 4. واجهة اللوحة (Blade)

في صفحة إعدادات التطبيق أو التكوين العام في اللوحة، أضف حقلين:

### رابط الـ API (api_base_url)

```html
<div class="form-group">
    <label for="api_base_url">رابط الـ API (API Base URL)</label>
    <input type="url" name="api_base_url" id="api_base_url" class="form-control"
           value="{{ old('api_base_url', $config['api_base_url'] ?? '') }}"
           placeholder="https://api.zayer.com">
    <small class="text-muted">اتركه فارغاً لاستخدام العنوان الافتراضي في التطبيق.</small>
</div>
```

### تفعيل وضع التطوير (development_mode)

```html
<div class="form-group">
    <div class="custom-control custom-switch">
        <input type="checkbox" class="custom-control-input" name="development_mode" id="development_mode" value="1"
               {{ ($config['development_mode'] ?? false) ? 'checked' : '' }}>
        <label class="custom-control-label" for="development_mode">تفعيل وضع التطوير</label>
    </div>
    <small class="text-muted">عند التفعيل يظهر في التطبيق بانر "وضع التطوير" وشاشة التطوير.</small>
</div>
```

عند الحفظ، احفظ القيم في جدول `app_config` (أو جدول الإعدادات الذي تستخدمه) ثم تأكد أن استجابة **GET /api/config/bootstrap** تقرأها وتُدرجها كما في البند 3.

---

## 5. ملخص سلوك التطبيق (Flutter)

| من اللوحة            | في التطبيق |
|----------------------|------------|
| `api_base_url` غير فارغ | يستخدمه التطبيق كـ base URL لجميع طلبات الـ API ويحفظه محلياً. |
| `development_mode: true` | يظهر بانر "وضع التطوير" في أعلى الشاشة، والضغط عليه يفتح شاشة التطوير (رابط الـ API الحالي ومعلومات التطوير). |

بعد تنفيذ الخطوات أعلاه في مشروع اللوحة، التطبيق سيعمل مع التحكم في **api_base_url** و**وضع التطوير** من اللوحة.
