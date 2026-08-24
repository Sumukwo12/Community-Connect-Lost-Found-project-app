# Community Connect - Lost & Found Application

A production-ready Lost & Found mobile application built with **Flutter (Material 3)** for Android/iOS, backed by a lightweight, secure **PHP 8+ REST API** with **MySQL/MariaDB** specifically designed for **cPanel Shared Hosting**.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Database Setup](#3-database-setup)
4. [cPanel Shared Hosting Deployment Guide](#4-cpanel-shared-hosting-deployment-guide)
5. [Backend API Reference & cURL Testing](#5-backend-api-reference--curl-testing)
6. [Flutter Mobile App Configuration](#6-flutter-mobile-app-configuration)
7. [Building Android APK & Release Bundle](#7-building-android-apk--release-bundle)
8. [Security & Production Hardening](#8-security--production-hardening)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Architecture Overview

```
+------------------------------------+
|  Flutter Android/iOS App           |
|  - Material 3 Design               |
|  - Provider State Management       |
|  - flutter_secure_storage (Tokens) |
|  - Multipart Image Uploads         |
+-----------------+------------------+
                  | HTTPS REST API (JSON)
                  v
+------------------------------------+
|  cPanel Apache Web Server          |
|  - .htaccess (Security, CORS, SSL) |
|  - PHP 8+ REST API Endpoints       |
|  - PDO Prepared Statements         |
|  - Bcrypt Password Hashing         |
|  - MIME-Validated Image Storage    |
+-----------------+------------------+
                  |
                  v
+------------------------------------+
|  MySQL / MariaDB Database          |
|  - Normalized Tables & Foreign Keys|
|  - Full-Text Search Indexes        |
+------------------------------------+
```

---

## 2. Project Structure

```
app-test/
├── database/
│   └── database.sql               # Normalized MySQL schema + category seed data
│
├── backend/                       # PHP REST API (Ready for cPanel public_html/api)
│   ├── .htaccess                  # Apache security rules, HTTPS enforcement, CORS
│   ├── env.php                    # Database & app credentials (edit on server)
│   ├── .env.example               # Reference config template
│   ├── config/
│   │   ├── database.php           # PDO singleton database connection
│   │   └── config.php             # CORS headers, JSON responders, security
│   ├── middleware/
│   │   └── auth.php               # Bearer token validation middleware
│   ├── auth/
│   │   ├── register.php           # User registration (bcrypt hash)
│   │   ├── login.php              # User authentication & token creation
│   │   ├── logout.php             # Token revocation
│   │   ├── profile.php            # User profile retrieval & update
│   │   └── forgot_password.php    # Password reset initiation
│   ├── items/
│   │   ├── create.php             # Post lost/found item (with image upload)
│   │   ├── list.php               # List items with search, filters & pagination
│   │   ├── get.php                # Single item details with poster contact
│   │   ├── update.php             # Edit item (owner only)
│   │   ├── delete.php             # Soft-delete item (owner only)
│   │   └── resolve.php            # Mark item resolved (owner only)
│   ├── categories/
│   │   └── list.php               # Retrieve category directory
│   ├── messages/
│   │   ├── send.php               # Send in-app message
│   │   └── list.php               # List conversations or thread history
│   ├── reports/
│   │   └── create.php             # Report inappropriate items
│   └── uploads/
│       ├── items/                 # Item uploaded pictures
│       └── profiles/              # User profile pictures
│
└── mobileapp/                   # Complete Flutter Android Source Code
    ├── pubspec.yaml               # Flutter dependencies & assets
    ├── android/                   # Native Android wrapper & manifest
    └── lib/
        ├── main.dart              # App root, MultiProvider & bottom navigation
        ├── config/
        │   └── api_config.dart    # Centralized API URLs & switchers
        ├── theme/
        │   └── app_theme.dart     # Material 3 light & dark themes
        ├── models/                # User, Item, Category, Message models
        ├── services/              # API, Auth, Item, Message HTTP services
        ├── providers/             # AuthProvider, ItemProvider, MessageProvider
        ├── widgets/               # ItemCard, CustomTextField, Shimmer, EmptyState
        ├── utils/                 # Validators, Date formatting, Helpers
        └── screens/
            ├── auth/              # Login, Register, Forgot Password
            ├── home/              # Modern dashboard with recent feeds
            ├── items/             # Browse, Details, Report Lost, Report Found
            ├── profile/           # Profile details, Edit profile, My Items tabs
            └── messages/          # Conversations list & live chat thread
```

---

## 3. Database Setup

### Step 1: Create Database in cPanel
1. Log into your **cPanel Dashboard**.
2. Under the **Databases** section, click **MySQL® Databases**.
3. Under **Create New Database**, enter a name (e.g., `cpaneluser_community`) and click **Create Database**.
4. Under **Add New User**, create a database username (e.g., `cpaneluser_app`) and a strong password. Click **Create User**.
5. Under **Add User to Database**, select your newly created user and database, click **Add**, check **ALL PRIVILEGES**, and click **Make Changes**.

### Step 2: Import SQL Schema via phpMyAdmin
1. Return to the cPanel main page and open **phpMyAdmin**.
2. Select your database from the left-hand menu.
3. Click the **Import** tab on the top menu.
4. Click **Choose File** and select `database/database.sql` from this project.
5. Click **Go** (or **Import**) at the bottom.
6. Verify that the 6 tables (`users`, `auth_tokens`, `categories`, `items`, `messages`, `reports`) are created and 10 categories are seeded.

---

## 4. cPanel Shared Hosting Deployment Guide

### Step 1: Upload Backend Files
1. In cPanel, open **File Manager**.
2. Navigate to `public_html` (or create a subdomain directory such as `api.yourdomain.com`).
3. Create a folder named `api` inside `public_html` (or upload directly into your subdomain folder).
4. Upload all files and folders from the `backend/` folder into this directory:
   ```
   public_html/api/
   ├── .htaccess
   ├── env.php
   ├── config/
   ├── middleware/
   ├── auth/
   ├── items/
   ├── categories/
   ├── messages/
   ├── reports/
   └── uploads/
       ├── items/
       └── profiles/
   ```

### Step 2: Set Directory Permissions
Ensure upload folders are writable by the web server:
- Right-click `uploads/items/` -> **Change Permissions** -> Set to `755` (or `775` if required by your host).
- Right-click `uploads/profiles/` -> **Change Permissions** -> Set to `755`.

### Step 3: Configure Database Credentials
Edit `env.php` using the cPanel File Manager Code Editor:
```php
define('DB_HOST',    'localhost');
define('DB_NAME',    'cpaneluser_community');
define('DB_USER',    'cpaneluser_app');
define('DB_PASS',    'YourStrongDbPasswordHere');
define('DB_PORT',    '3306');

define('APP_NAME',   'Community Connect');
define('APP_ENV',    'production');

// Generate a random 64-character secret
define('APP_SECRET', '4f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a');

// Your full API domain (without trailing slash)
define('APP_URL',    'https://lost.strand.co.ke');
```

### Step 4: Enable Free SSL (Let's Encrypt / AutoSSL)
1. In cPanel, search for **SSL/TLS Status**.
2. Select your domain or subdomain and click **Run AutoSSL**.
3. Verify that HTTPS is active by opening `https://lost.strand.co.ke/categories/list.php` in your browser. You should receive a JSON response: `{"success":true,"message":"Categories retrieved.",...}`.

---

## 5. Backend API Reference & cURL Testing

### 1. Categories List (Public)
```bash
curl -X GET "https://lost.strand.co.ke/categories/list.php"
```

### 2. User Registration
```bash
curl -X POST "https://lost.strand.co.ke/auth/register.php" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Jane Doe",
    "email": "jane@example.com",
    "phone": "+1234567890",
    "password": "Password123!",
    "confirm_password": "Password123!"
  }'
```

### 3. User Login
```bash
curl -X POST "https://lost.strand.co.ke/auth/login.php" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane@example.com",
    "password": "Password123!"
  }'
```
*Returns Bearer token:*
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "a1b2c3d4e5f6...",
    "user": { "id": 1, "full_name": "Jane Doe", "email": "jane@example.com", "phone": "+1234567890" }
  }
}
```

### 4. Create Lost/Found Item (Authenticated + Image Upload)
```bash
curl -X POST "https://api.yourdomain.com/items/create.php" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "type=lost" \
  -F "title=Black Leather Wallet" \
  -F "description=Lost wallet with student ID and credit cards near the cafeteria." \
  -F "category_id=4" \
  -F "location=University Cafeteria" \
  -F "date_occurred=2026-08-24" \
  -F "time_occurred=13:30" \
  -F "image=@/path/to/local/photo.jpg"
```

### 5. Browse Items with Search & Filters
```bash
curl -X GET "https://api.yourdomain.com/items/list.php?type=lost&category_id=4&page=1&per_page=15"
```

### 6. Send In-App Message
```bash
curl -X POST "https://api.yourdomain.com/messages/send.php" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "receiver_id": 2,
    "item_id": 1,
    "message": "Hi Jane, I found your wallet at the front desk!"
  }'
```

---

## 6. Flutter Mobile App Configuration

### Step 1: Set Your Production Base URL
Open `flutter_app/lib/config/api_config.dart` and update the production URL:
```dart
class ApiConfig {
  static const String _productionUrl = 'https://api.yourdomain.com';
  static const String _developmentUrl = 'http://10.0.2.2/community-connect/api'; // Android Emulator

  // Set to true for release build
  static const bool _isProduction = true;
  ...
}
```

### Step 2: Install Flutter Dependencies
Navigate into the Flutter project folder:
```bash
cd flutter_app
flutter pub get
```

### Step 3: Run the App in Development
- **Android Emulator**: `flutter run` (Connects to `10.0.2.2` which points to your local machine's `localhost`)
- **Physical Device**: Ensure your computer and device are on the same Wi-Fi, and set `_developmentUrl` to your machine's LAN IP (e.g. `http://192.168.1.100/...`).

### Step 4: Run Flutter Tests
```bash
flutter test
```

---

## 7. Building Android APK & Release Bundle

### Step 1: Generate Release APK
To build an APK for direct installation on Android phones:
```bash
cd flutter_app
flutter build apk --release
```
The compiled APK will be located at:
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`

### Step 2: Generate Android App Bundle (Google Play Store)
To build an `.aab` file ready for submission to Google Play Console:
```bash
flutter build appbundle --release
```
The App Bundle will be located at:
`flutter_app/build/app/outputs/bundle/release/app-release.aab`

---

## 8. Security & Production Hardening

1. **Prepared Statements**: All SQL queries utilize PDO parameter binding with explicit integer/string typing to prevent SQL injection.
2. **Password Protection**: Passwords are never stored in plaintext and use PHP's `PASSWORD_BCRYPT` with cost factor 12.
3. **MIME-Type File Upload Validation**: Uploaded images are validated on the server using PHP `finfo` against allowed MIME types (`image/jpeg`, `image/png`, `image/webp`). PHP execution inside the `uploads/` directory is blocked via `.htaccess`.
4. **Apache `.htaccess`**: Direct HTTP access to `env.php`, `.env`, `config/`, and `middleware/` directories is forbidden (`403 Forbidden`).
5. **Data Ownership Check**: Update and delete endpoints strictly check that `item.user_id === authenticated_user.id`.

---

## 9. Troubleshooting

| Issue | Cause | Solution |
|---|---|---|
| **CORS error on web / mobile** | Missing CORS headers | `.htaccess` and `config.php` are configured with wildcard `*` by default. For strict production, set `ALLOWED_ORIGINS` in `env.php`. |
| **Image Upload Fails (422/500)** | Upload directory permissions | In cPanel File Manager, ensure `public_html/api/uploads/items/` permission is set to `755`. |
| **Database Connection Failed** | Incorrect credentials in `env.php` | Ensure DB user is assigned to the DB with "ALL PRIVILEGES" in cPanel MySQL Databases. |
| **Android Cleartext HTTP blocked** | Android 9+ requires HTTPS | Ensure SSL is enabled on your host, or keep `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` for dev. |
| **404 on API endpoints** | Incorrect base URL path | Ensure your `ApiConfig.baseUrl` matches the exact folder structure on your server (e.g. `https://api.domain.com` vs `https://domain.com/api`). |
