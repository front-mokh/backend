<?php

namespace Tests\Feature\Onboarding;

use App\Enums\UserType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_verified_brand_user_can_create_brand_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/brand', [
            'name' => 'My Brand',
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['name' => 'My Brand']);

        $this->assertDatabaseHas('brand_profiles', [
            'user_id' => $user->id,
            'name' => 'My Brand',
        ]);

        $this->assertNotNull($user->fresh()->onboarding_completed_at);
    }

    public function test_verified_creator_user_can_create_creator_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/creator', [
            'first_name' => 'John',
            'last_name' => 'Doe',
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['first_name' => 'John']);

        $this->assertDatabaseHas('creator_profiles', [
            'user_id' => $user->id,
            'first_name' => 'John',
        ]);

        $this->assertNotNull($user->fresh()->onboarding_completed_at);
    }

    public function test_brand_user_cannot_create_creator_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/creator', [
            'first_name' => 'John',
            'last_name' => 'Doe',
        ]);

        $response->assertStatus(403);
    }

    public function test_creator_user_cannot_create_brand_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/brand', [
            'name' => 'My Brand',
        ]);

        $response->assertStatus(403);
    }

    public function test_unverified_user_cannot_create_profile(): void
    {
        $user = User::factory()->unverified()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/brand', [
            'name' => 'My Brand',
        ]);

        $response->assertStatus(403);
    }
}
