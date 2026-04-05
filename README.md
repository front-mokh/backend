# MokInfluence — Backend & Mobile

> Influencer marketing platform connecting **brands** with **creators** for campaign collaborations.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Laravel 12, PHP 8.2+ |
| Auth | Laravel Sanctum (token-based) |
| Real-time | Laravel Reverb (WebSocket broadcasting) |
| Admin | Filament v3 |
| Mobile | React Native / Expo |
| Styling | NativeWind (Tailwind CSS) |
| Navigation | Expo Router (file-based) |
| Database | SQLite (dev) — easily swappable via `.env` |

## Features

- **Authentication** — Signup, login, logout, email verification (queued)
- **Onboarding** — Separate flows for brands (name + industries) and creators (profile + categories + social links)
- **Announcements** — Brands create campaigns with budget, deliverables, platform requirements, and deadlines
- **Applications** — Creators apply to announcements — brands accept or reject
- **Collaborations** — Workspace created on acceptance with messaging, deliverable submissions, and status tracking
- **Notifications** — In-app DB notifications + Expo push notifications + WebSocket broadcast
- **Admin Panel** — Filament dashboard for managing users, announcements, categories, platforms, and deliverables

## Getting Started

### Prerequisites

- PHP 8.2+
- Composer
- Node.js 18+
- Expo CLI (`npx expo`)

### Backend Setup

```bash
# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate app key
php artisan key:generate

# Run migrations
php artisan migrate

# (Optional) Seed the database
php artisan db:seed

# Start the server
php artisan serve --host=0.0.0.0 --port=8001
```

### Mobile App Setup

```bash
cd react_native_app/mobile

# Install dependencies
npm install

# Configure API URL in .env
# EXPO_PUBLIC_API_URL=http://<your-local-ip>:8001/api

# Start Expo
EXPO_OFFLINE=1 REACT_NATIVE_PACKAGER_HOSTNAME=<your-local-ip> npx expo start --clear
```

> ⚠️ Use `EXPO_OFFLINE=1` to skip Expo's network version checks on unstable internet.
> ⚠️ If your IP changes, update `react_native_app/mobile/.env` → `EXPO_PUBLIC_API_URL`.

### Queue Worker (for async email)

```bash
php artisan queue:work
```

## API Endpoints

### Public
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/signup` | Register a new user |
| POST | `/api/login` | Log in and receive token |
| GET | `/api/categories` | List all categories |
| GET | `/api/industries` | List all industries |
| GET | `/api/platforms` | List all platforms |
| GET | `/api/deliverable-types` | List deliverable types |
| GET | `/api/influencer-tiers` | List influencer tiers |

### Authenticated (Bearer token required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/logout` | Revoke token |
| GET | `/api/user` | Get current user + profile |
| POST | `/api/onboarding/brand` | Complete brand onboarding |
| POST | `/api/onboarding/creator` | Complete creator onboarding |
| GET | `/api/announcements` | List announcements |
| POST | `/api/announcements` | Create announcement |
| POST | `/api/announcements/{id}/apply` | Apply to announcement |
| GET | `/api/applications` | List applications |
| POST | `/api/applications/{id}/accept` | Accept application |
| POST | `/api/applications/{id}/reject` | Reject application |
| GET | `/api/collaborations` | List collaborations |
| GET | `/api/collaborations/{id}` | Collaboration details |
| POST | `/api/collaborations/{id}/messages` | Send message |
| POST | `/api/collaborations/{id}/heartbeat` | Refresh chat presence |
| POST | `/api/collaborations/{id}/read` | Mark messages as read |
| POST | `/api/collaborations/{id}/submissions` | Submit deliverable |
| GET | `/api/notifications` | List notifications |

## Testing

```bash
php artisan test
```

## Project Structure

```
├── app/
│   ├── Enums/              # UserType, ProjectStatus, ApplicationStatus
│   ├── Events/             # WebSocket events (NewMessage, NewNotification)
│   ├── Filament/           # Admin panel resources
│   ├── Http/Controllers/
│   │   ├── Api/            # Main API controllers
│   │   ├── Auth/           # Signup, Login, Email verification
│   │   └── Onboarding/    # Brand & Creator onboarding
│   ├── Models/             # Eloquent models (16 models)
│   ├── Policies/           # Authorization policies
│   └── Services/           # NotificationService (DB + Push + WebSocket)
├── database/migrations/    # 27 migrations
├── routes/api.php          # All API routes
├── react_native_app/mobile/
│   ├── app/                # Expo Router screens
│   ├── components/         # UI components (Button, Card, Input, etc.)
│   ├── contexts/           # AuthContext
│   ├── hooks/              # Custom React hooks
│   └── lib/                # API client, utilities, colors
└── tests/                  # PHPUnit feature & unit tests
```

## License

MIT
