<?php

namespace Tests\Feature\Onboarding;

use App\Enums\UserType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingTest extends TestCase
{
    use RefreshDatabase;

    public function test_verified_brand_user_can_access_onboarding_endpoint(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        // Test that the onboarding endpoint exists and validates input
        $response = $this->postJson('/api/onboarding/brand', []);

        // Should get 422 (validation error) not 404, proving the route exists
        $response->assertStatus(422);
    }

    public function test_unverified_user_cannot_access_onboarding(): void
    {
        $user = User::factory()->unverified()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/brand', []);

        $response->assertStatus(403);
    }
}
