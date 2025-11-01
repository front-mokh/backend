<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_verify_email(): void
    {
        $user = User::factory()->create([
            'email_verified_at' => null,
        ]);

        Notification::fake();

        $user->sendEmailVerificationNotification();

        Notification::assertSentTo($user, VerifyEmail::class, function ($notification) use ($user) {
            $verificationUrl = $notification->toMail($user)->actionUrl;

            $this->get($verificationUrl);

            return true;
        });

        $this->assertNotNull($user->fresh()->email_verified_at);
    }
}
