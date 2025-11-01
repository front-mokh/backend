<?php

namespace Tests\Feature\Onboarding;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingTest extends TestCase
{
    use RefreshDatabase;

    public function test_verified_user_can_access_onboarding(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user);

        $response = $this->getJson('/api/onboarding');

        $response->assertStatus(200)
            ->assertJsonFragment(['message' => 'Welcome to the onboarding process!']);
    }

    public function test_unverified_user_cannot_access_onboarding(): void
    {
        $user = User::factory()->unverified()->create();

        $this->actingAs($user);

        $response = $this->getJson('/api/onboarding');

        $response->assertStatus(403);
    }
}
