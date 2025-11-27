# Project Knowledge Base

## Recent Changes Log
### [2025-11-21] Create Categories Endpoint
- **Status**: IMPLEMENTING
- **Description**: Created a new API endpoint to retrieve all categories with their `id`, `name`, and `description`.
- **Impact**:
    - `app/Http/Controllers/Api/CategoryController.php`: New controller created.
    - `routes/api.php`: New GET route `/api/categories` added.
- **Implementation**:
    - Created `Api\CategoryController`.
    - Implemented the `index` method in `Api\CategoryController` to fetch all categories and return them as a JSON response.
    - Added `Route::get('/categories', [CategoryController::class, 'index']);` to `routes/api.php`.
- **Testing**:
    - Manual testing by accessing the `/api/categories` endpoint to verify that a JSON array of categories (with `id`, `name`, `description`) is returned.

### [2025-11-21] Update Creator Onboarding Endpoint
- **Status**: IMPLEMENTING
- **Description**: Modified the `storeCreatorProfile` method in `OnboardingController` to match the new schema for social links and categories, including validation and French error messages.
- **Impact**:
    - `app/Http/Controllers/Onboarding/OnboardingController.php`: Updated the `storeCreatorProfile` method.
- **Implementation**:
    - Removed old social media handle fields from validation and `CreatorProfile` creation.
    - Added new validation rules for `links` (array of URLs, min 1, max 6) and `categories` (array of existing category IDs, min 1, max 3).
    - Integrated French error messages for all validation rules in `storeCreatorProfile` and `storeBrandProfile`.
    - Modified `CreatorProfile::create` to use the new `nickname` field.
    - Added logic to store `SocialLink` records associated with the user.
    - Added logic to attach `Category` records to the user.
- **Testing**:
    - Functional testing of the `/api/onboarding/creator` endpoint with valid and invalid data for links, categories, and other profile fields.
    - Verify that French error messages are returned for invalid inputs.

### [2025-11-21] Add Nickname to Creator Profile
- **Status**: IMPLEMENTING
- **Description**: Added an optional `nickname` field to the `creator_profiles` table and model.
- **Impact**:
    - `database/migrations/2025_10_31_152641_create_creator_profiles_table.php`: Modified to include a `nickname` column.
    - `app/Models/CreatorProfile.php`: Modified to include `nickname` in the `$fillable` property and removed the deprecated `instagram_handle` and `tiktok_handle` from `$fillable`.
- **Implementation**:
    - Added `nickname` column (`string`, nullable) to the `creator_profiles` table.
    - Updated `CreatorProfile` model's `$fillable` array.
- **Testing**:
    - Manual verification after running `php artisan migrate:refresh` to ensure the column is added correctly and the model can access it.
    - Future: Create unit/feature tests for CreatorProfile nickname management.

### [2025-11-21] Add User Categories
- **Status**: IMPLEMENTING
- **Description**: Added a new `Category` model and a many-to-many relationship between `Users` and `Categories` to track user interests or work areas.
- **Impact**:
    - `app/Models/Category.php`: New model created for categories.
    - `app/Models/User.php`: Modified to include a `belongsToMany` relationship for `categories()`.
    - `database/migrations/2025_11_21_165518_create_categories_table.php`: New migration created to establish the `categories` table.
    - `database/migrations/2025_11_21_165544_create_user_categories_table.php`: New migration created to establish the `user_categories` pivot table.
- **Implementation**:
    - Created `Category` model with `$fillable` properties for `name` and `description`.
    - Created `categories` table with `id`, `name` (unique), `description`, and timestamps.
    - Created `user_categories` pivot table with `id`, `user_id`, `category_id`, and a unique constraint on the combination of `user_id` and `category_id`.
    - Added `belongsToMany` relationships in both `User` and `Category` models for `categories()` and `users()` respectively.
- **Testing**:
    - Manual verification after running `php artisan migrate` to ensure the tables are created correctly and relationships are established.
    - Future: Create unit/feature tests for Category creation, retrieval, and association with users.

### [2025-11-21] Refactor Social Media Links
- **Status**: IMPLEMENTING
- **Description**: Refactored the storage of social media links from hardcoded columns in `creator_profiles` to a dedicated `social_links` table linked to the `users` table.
- **Impact**:
    - `database/migrations/2025_10_31_152641_create_creator_profiles_table.php`: Modified to remove `instagram_handle` and `tiktok_handle` columns.
    - `database/migrations/2025_11_21_163843_create_social_links_table.php`: Modified to create a `social_links` table with `user_id` (foreign key to users), `url`, and `is_verified` (boolean, default false). The previous pivot table creation was removed.
    - `app/Models/SocialLink.php`: Modified to include `user_id` and `is_verified` in `$fillable` and define the `user()` relationship.
    - `app/Models/User.php`: Modified to include a `hasMany` relationship for `socialLinks()`.
    - `app/Models/CreatorProfile.php`: No direct changes, but its associated data structure has changed.
    - `app/Models/BrandProfile.php`: No direct changes, but its associated data structure has changed.
- **Implementation**:
    - Removed `instagram_handle` and `tiktok_handle` columns from `creator_profiles` table definition.
    - Created `social_links` table with `id`, `user_id`, `url`, `is_verified` (default false), and timestamps. `user_id` is a foreign key to the `users` table. A unique constraint was added on `user_id` and `url`.
    - Updated `SocialLink` model to reflect the new table structure and relationships.
    - Updated `User` model to establish a `hasMany` relationship with `SocialLink`.
- **Testing**:
    - Manual verification after running `php artisan migrate:refresh` (as requested by the user) to ensure the tables are created correctly and relationships are established.
    - Future: Create unit/feature tests for SocialLink creation, retrieval, and association with users.

### [2025-11-21] Signup Controller Optimization & Logout Functionality
- **Status**: IMPLEMENTED
- **Description**: Optimized the signup process by queuing email verification notifications and added a new API endpoint for user logout.
- **Impact**:
    - `app/Http/Controllers/Auth/SignupController.php`: Reduced execution time by making email verification asynchronous.
    - `app/Models/User.php`: Modified to use a queued email verification notification.
    - `app/Notifications/Auth/QueuedVerifyEmail.php`: New file created for the queued email verification notification.
    - `app/Http/Controllers/Auth/LoginController.php`: Added a `logout` method to revoke user access tokens.
    - `routes/api.php`: Added a new POST route `/api/logout` for user logout.
- **Implementation**:
    - **Signup Optimization**:
        1. Created `app/Notifications/Auth/QueuedVerifyEmail.php` which extends `Illuminate\Auth\Notifications\VerifyEmail` and implements `Illuminate\Contracts\Queue\ShouldQueue`. This ensures email verification is pushed to the queue for background processing.
        2. Overrode the `sendEmailVerificationNotification()` method in `app/Models/User.php` to use the new `QueuedVerifyEmail` notification. This change ensures that when the `Registered` event is fired during signup, the email verification notification is queued instead of being sent synchronously.
    - **Logout Functionality**:
        1. Added a `logout` method to `app/Http/Controllers/Auth/LoginController.php`. This method uses `currentAccessToken()->delete()` to revoke the current user's personal access token, effectively logging them out.
        2. Added a new route `Route::post('/logout', [LoginController::class, 'logout'])->middleware('auth:sanctum');` to `routes/api.php` to expose the logout functionality.
- **Testing**:
    - **Signup Optimization**: Verified by running `tests/Feature/Auth/SignupTest.php` after temporarily adding a test case that used `Notification::fake()` and `Notification::assertSentTo()` to confirm that `App\Notifications\Auth\QueuedVerifyEmail` was dispatched. All existing tests passed, and the added test confirmed the notification was sent.
    - **Logout Functionality**: Verified by running `tests/Feature/Auth/LoginTest.php` after temporarily adding a test case that logged in a user, called the logout endpoint, and then asserted a successful logout (HTTP 200) and token invalidation (checked `assertDatabaseMissing`).
    - **Queue Worker**: To process queued emails, a queue worker must be running (e.g., `php artisan queue:work`).

## Architecture Overview
- System design patterns
- Key architectural decisions and rationale

## Component Inventory
- Major modules and their responsibilities
- Inter-component relationships and data flow

## Configuration Map
- All config files and their purposes
- Environment variables and their usage
- Build and deployment configuration

## Data Flow & Integration Points
- How data moves through the system
- APIs, databases, external services
- Authentication and authorization patterns

## Testing Strategy
- Current test patterns and coverage
- Testing utilities and frameworks
- Test data management

## Development Patterns
- Code style and conventions
- Common abstractions and utilities
- Error handling patterns