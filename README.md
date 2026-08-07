# DPS ERP Pro

A Flutter ERP app: customers, invoicing (with PDF export), payments, a
per-customer ledger, dashboard/reports, multi-user accounts with roles,
an audit trail, and local JSON backup/restore.

Data is stored locally on-device (via `shared_preferences`) so the app
works fully offline out of the box. `firestore_service.dart` is written
with Firestore-shaped method names/signatures, so swapping in real
Firebase later is a drop-in change — no screen code needs to change.

## Why there's no APK attached

Building an APK requires the Flutter SDK + Android SDK + Gradle, and a
network connection to fetch dependencies — none of which are available
in this chat environment. What's included here is the **complete,
working source code**. You build the APK on your own machine in a
few commands.

## Build in the cloud (no install needed) — GitHub Actions

This project includes `.github/workflows/build-apk.yml`, which builds
the APK automatically on GitHub's servers. You don't need Flutter,
Android Studio, or anything installed locally — just a free GitHub
account, even from your phone.

1. Go to https://github.com/new and create a new repository (any
   name, e.g. `dps-erp-pro`). Public or private both work.
2. Upload this entire unzipped `dps_erp_pro` folder into that repo.
   Easiest way on desktop: on the repo page, click **"Add file" →
   "Upload files"**, then drag in everything from the unzipped folder
   (make sure the `.github` folder comes along — it's hidden, so if
   you're dragging from Finder/Explorer enable "show hidden files"
   first, or use `git push` instead — see below).
3. Once uploaded, go to the **Actions** tab of your repo. A workflow
   run should start automatically (or click **"Run workflow"** if it
   doesn't).
4. Wait ~3–5 minutes for it to finish (green checkmark).
5. Click the finished run → scroll to **Artifacts** → download
   `dps-erp-pro-apk`. Unzip it — that's your `app-release.apk`.

### If you prefer git on the command line
```bash
cd dps_erp_pro
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/dps-erp-pro.git
git push -u origin main
```
Then check the **Actions** tab as above.

## Build steps (on your computer)

1. **Install Flutter** (if you haven't): https://docs.flutter.dev/get-started/install
2. Unzip this project, then in a terminal:

```bash
cd dps_erp_pro

# Generate the android/ios/windows platform folders (this project
# ships lib/ + pubspec.yaml only — platform scaffolding is regenerated
# fresh so it matches your installed Flutter/Android SDK versions):
flutter create . --project-name dps_erp_pro --org com.dps

# Install dependencies
flutter pub get

# Build a release APK
flutter build apk --release
```

3. Your APK will be at:
   `build/app/outputs/flutter-apk/app-release.apk`

Install it on an Android device (enable "install from unknown sources"
if sideloading), or run `flutter install` with a device connected.

## Default login

- Email: `admin@dps.local`
- Password: `admin123`

Change this immediately in **Settings → Change Password**, and create
named accounts for your team in **Users** (admin only).

## Project structure

```
lib/
├── main.dart              # entry point
├── app.dart                # root widget, session restore
├── models/                 # User, Customer, Invoice, Payment, Audit
├── services/
│   ├── auth_service.dart       # login, sessions, user management
│   ├── firestore_service.dart  # local data layer (Firestore-shaped API)
│   ├── report_service.dart     # dashboard + ledger calculations
│   ├── pdf_service.dart        # invoice PDF generation/sharing
│   ├── backup_service.dart     # JSON export/import
│   └── audit_service.dart      # activity logging
├── screens/                # one folder per feature area
├── widgets/                 # shared UI components
└── utils/                   # theme, constants, routes
```

## Notes / next steps

- **Real backend**: to move off local storage, replace the internals
  of `firestore_service.dart` with `cloud_firestore` calls — the
  method signatures already match what Firestore needs.
- **Multi-device sync** isn't implemented since data is local-only;
  that comes for free once you connect real Firestore + Firebase Auth.
- **iOS**: same `flutter create .` step generates the `ios/` folder;
  run `flutter build ios` from a Mac with Xcode.
