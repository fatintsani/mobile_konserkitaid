# KonserKita Application Documentation

KonserKita is a comprehensive event management and ticketing platform consisting of three parts:
- **Laravel Backend API**: Handles business logic, authentication, database, and Midtrans webhook.
- **Flutter Mobile App**: Customer and Organizer app for browsing events, purchasing tickets, and managing events/checking-in.
- **React Admin Panel**: For Admin and Super Admin to manage users, events, and reports.

---

## 1. Environment Variables & Midtrans Setup

### Backend (`.env`)
Ensure you have the following variables set in `konserkita_api/.env`:
```env
APP_NAME=KonserKita
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=konserkita
DB_USERNAME=root
DB_PASSWORD=

# Midtrans Configuration
MIDTRANS_SERVER_KEY=your_server_key
MIDTRANS_CLIENT_KEY=your_client_key
MIDTRANS_IS_PRODUCTION=true
MIDTRANS_IS_SANITIZED=true
MIDTRANS_IS_3DS=true
```

## 2. Backend Setup
1. `cd konserkita_api`
2. `composer install`
3. `cp .env.example .env` and configure it.
4. `php artisan key:generate`
5. `php artisan storage:link` (Crucial for banner images)
6. `php artisan migrate --seed`
7. Set up Queue Worker if sending emails: `php artisan queue:work`
8. Configure CORS in `config/cors.php` to allow your React Admin domain.

## 3. Flutter Setup
1. `cd konserkita_mobile`
2. `flutter pub get`
3. Update `lib/utils/constants.dart` with your production API URL and Midtrans Client Key.
4. `flutter run --release` or `flutter build apk`

## 4. React Admin Setup
1. `cd konserkita_admin`
2. `npm install`
3. Update `src/api/axios.js` `baseURL` to your production API URL.
4. `npm run build`
5. Serve the `dist` folder on your web server.

## 5. Git Workflow & Testing Guide
**Workflow:**
- `main`: Stable release branch.
- `develop`: Main development branch.
- `feature/*`: Feature development.

**Testing:**
Run backend tests with:
```bash
cd konserkita_api
php artisan test
```
Verify Flutter code:
```bash
cd konserkita_mobile
flutter analyze
```

## 6. Dummy Account List
| Role | Email | Password |
|---|---|---|
| Super Admin | superadmin@example.com | password |
| Admin | admin@example.com | password |
| Organizer | organizer@example.com | password |
| Customer | customer@example.com | password |
