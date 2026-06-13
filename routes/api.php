<?php

use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CollaborationController;
use App\Http\Controllers\Api\DeliverableTypeController;
use App\Http\Controllers\Api\IndustryController;
use App\Http\Controllers\Api\InfluencerTierController;
use App\Http\Controllers\Api\PlatformController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Auth\EmailVerificationNotificationController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\SignupController;
use App\Http\Controllers\Auth\VerifyEmailController;
use App\Http\Controllers\Onboarding\OnboardingController;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;

// Enable broadcast auth for Sanctum clients on /api/broadcasting/auth
Broadcast::routes(['middleware' => ['auth:sanctum']]);
require base_path('routes/channels.php');

// ──────────────────────────────────────────────
// Public routes
// ──────────────────────────────────────────────
Route::post('/login', [LoginController::class, 'store']);
Route::post('/signup', [SignupController::class, 'store']);

Route::get('/email/verify/{id}/{hash}', [VerifyEmailController::class, '__invoke'])
    ->middleware(['signed', 'throttle:6,1'])
    ->name('verification.verify');

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/industries', [IndustryController::class, 'index']);
Route::get('/platforms', [PlatformController::class, 'index']);
Route::get('/deliverable-types', [DeliverableTypeController::class, 'index']);
Route::get('/influencer-tiers', [InfluencerTierController::class, 'index']);

// ──────────────────────────────────────────────
// Auth-required routes (Sanctum)
// ──────────────────────────────────────────────
Route::post('/email/verification-notification', [EmailVerificationNotificationController::class, 'store'])
    ->middleware(['auth:sanctum', 'throttle:6,1']);

Route::post('/logout', [LoginController::class, 'logout'])->middleware('auth:sanctum');

Route::post('/onboarding/brand', [OnboardingController::class, 'storeBrandProfile'])
    ->middleware(['auth:sanctum', 'verified']);

Route::post('/onboarding/creator', [OnboardingController::class, 'storeCreatorProfile'])
    ->middleware(['auth:sanctum', 'verified']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [UserController::class, 'show']);

    // Announcements
    Route::apiResource('announcements', AnnouncementController::class);
    Route::post('/announcements/{announcement}/close', [AnnouncementController::class, 'close']);

    // Applications
    Route::post('/announcements/{announcement}/apply', [ApplicationController::class, 'store']);
    Route::get('/applications', [ApplicationController::class, 'index']); // Brand views applications for their announcements
    Route::get('/applications/{application}', [ApplicationController::class, 'show']);
    Route::post('/applications/{application}/accept', [ApplicationController::class, 'accept']);
    Route::post('/applications/{application}/reject', [ApplicationController::class, 'reject']);

    // Creator discovery
    Route::get('/creators', [UserController::class, 'creators']);

    // Collaborations
    Route::get('/collaborations', [CollaborationController::class, 'index']);
    Route::get('/collaborations/{collaboration}/messages', [CollaborationController::class, 'messages']);
    Route::get('/collaborations/{collaboration}', [CollaborationController::class, 'show']);
    Route::post('/collaborations/{collaboration}/messages', [CollaborationController::class, 'sendMessage']);
    Route::post('/collaborations/{collaboration}/heartbeat', [CollaborationController::class, 'heartbeat']);
    Route::post('/collaborations/{collaboration}/read', [CollaborationController::class, 'markAsRead']);
    Route::post('/collaborations/{collaboration}/complete', [CollaborationController::class, 'complete']);
    Route::patch('/collaborations/{collaboration}/status', [CollaborationController::class, 'updateStatus']);
    Route::post('/collaborations/{collaboration}/submissions', [CollaborationController::class, 'submitDeliverable']);
    Route::patch('/submissions/{submission}', [CollaborationController::class, 'updateSubmissionStatus']);

    // Notifications
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [\App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{notification}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [\App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/all', [\App\Http\Controllers\Api\NotificationController::class, 'destroyAll']);
    Route::delete('/notifications/{notification}', [\App\Http\Controllers\Api\NotificationController::class, 'destroy']);
    Route::post('/push-tokens', [\App\Http\Controllers\Api\NotificationController::class, 'storeDeviceToken']);
    Route::delete('/push-tokens', [\App\Http\Controllers\Api\NotificationController::class, 'destroyDeviceToken']);
    Route::post('/user/expo-push-token', [\App\Http\Controllers\Api\NotificationController::class, 'storePushToken']);
});
