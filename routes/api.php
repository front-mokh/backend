<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\EmailVerificationNotificationController;
use App\Http\Controllers\Auth\SignupController;
use App\Http\Controllers\Auth\VerifyEmailController;
use App\Http\Controllers\Onboarding\OnboardingController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\IndustryController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/login', [LoginController::class, 'store']);
Route::post('/signup', [SignupController::class, 'store']);
Route::post('/logout', [LoginController::class, 'logout'])->middleware('auth:sanctum');

Route::get('/email/verify/{id}/{hash}', [VerifyEmailController::class, '__invoke'])
    ->middleware(['signed', 'throttle:6,1'])
    ->name('verification.verify');

Route::post('/email/verification-notification', [EmailVerificationNotificationController::class, 'store'])
    ->middleware(['auth:sanctum', 'throttle:6,1']);

Route::get('/user', [UserController::class, 'show'])->middleware('auth:sanctum');

Route::post('/onboarding/brand', [OnboardingController::class, 'storeBrandProfile'])
    ->middleware(['auth:sanctum', 'verified']);

Route::post('/onboarding/creator', [OnboardingController::class, 'storeCreatorProfile'])
    ->middleware(['auth:sanctum', 'verified']);

// New route for categories
Route::get('/categories', [CategoryController::class, 'index']);

// New route for industries
Route::get('/industries', [IndustryController::class, 'index']);

use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\PlatformController;
use App\Http\Controllers\Api\DeliverableTypeController;
use App\Http\Controllers\Api\InfluencerTierController;

Route::get('/platforms', [PlatformController::class, 'index']);
Route::get('/deliverable-types', [DeliverableTypeController::class, 'index']);
Route::get('/influencer-tiers', [InfluencerTierController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user()->load(['brandProfile', 'creatorProfile', 'socialLinks']);
    });

    // Announcements
    Route::apiResource('announcements', AnnouncementController::class);

    // Applications
    Route::post('/announcements/{announcement}/apply', [ApplicationController::class, 'store']);
    Route::get('/applications', [ApplicationController::class, 'index']); // Brand views applications for their announcements
    Route::post('/applications/{application}/accept', [ApplicationController::class, 'accept']);
    Route::post('/applications/{application}/reject', [ApplicationController::class, 'reject']);
});