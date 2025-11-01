<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\EmailVerificationNotificationController;
use App\Http\Controllers\Auth\SignupController;
use App\Http\Controllers\Auth\VerifyEmailController;
use App\Http\Controllers\Onboarding\OnboardingController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/login', [LoginController::class, 'store']);
Route::post('/signup', [SignupController::class, 'store']);

Route::get('/email/verify/{id}/{hash}', [VerifyEmailController::class, '__invoke'])
    ->middleware(['signed', 'throttle:6,1'])
    ->name('verification.verify');

Route::post('/email/verification-notification', [EmailVerificationNotificationController::class, 'store'])
    ->middleware(['auth:sanctum', 'throttle:6,1']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/onboarding/brand', [OnboardingController::class, 'storeBrandProfile'])
    ->middleware(['auth:sanctum', 'verified']);

Route::post('/onboarding/creator', [OnboardingController::class, 'storeCreatorProfile'])
    ->middleware(['auth:sanctum', 'verified']);
