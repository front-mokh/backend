<?php

namespace Tests\Feature;

use App\Enums\UserType;
use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class UserJourneyTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_user_journey(): void
    {
        // 1. Signup
        Notification::fake();

        $response = $this->postJson('/api/signup', [
            'email' => 'test@example.com',
            'password' => 'password',
            'type' => UserType::BRAND->value,
        ]);

        $response->assertStatus(201);
        $user = User::first();
        $this->assertNotNull($user);

        // 2. Verification
        Notification::assertSentTo($user, VerifyEmail::class, function ($notification) use ($user) {
            $verificationUrl = $notification->toMail($user)->actionUrl;
            $this->get($verificationUrl);
            return true;
        });

        $this->assertNotNull($user->fresh()->email_verified_at);

        // 3. Login
        $response = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);

        $response->assertStatus(200);
        $token = $response->json('token');
        $this->assertNotEmpty($token);

        // 4. Onboarding
        $response = $this->withToken($token)->postJson('/api/onboarding/brand', [
            'name' => 'My Awesome Brand',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('brand_profiles', [
            'user_id' => $user->id,
            'name' => 'My Awesome Brand',
        ]);
        $this->assertNotNull($user->fresh()->onboarding_completed_at);
    }
}
