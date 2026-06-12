<?php

namespace Tests\Feature\Onboarding;

use App\Enums\UserType;
use App\Models\Category;
use App\Models\Industry;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_verified_brand_user_can_create_brand_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);
        $industry = Industry::create(['name' => 'Tech']);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/brand', [
            'name' => 'My Brand',
            'phone' => '0612345678',
            'location' => 'Paris',
            'links' => ['https://instagram.com/mybrand'],
            'industries' => [$industry->id],
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['name' => 'My Brand']);

        $this->assertDatabaseHas('brand_profiles', [
            'user_id' => $user->id,
            'name' => 'My Brand',
        ]);

        $this->assertNotNull($user->fresh()->onboarding_completed_at);
    }

    public function test_brand_onboarding_can_be_submitted_again_to_update_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);
        $tech = Industry::create(['name' => 'Tech']);
        $fashion = Industry::create(['name' => 'Fashion']);

        $this->actingAs($user);

        $this->postJson('/api/onboarding/brand', [
            'name' => 'My Brand',
            'phone' => '0612345678',
            'location' => 'Paris',
            'links' => ['https://instagram.com/mybrand'],
            'industries' => [$tech->id],
        ])->assertStatus(201);

        $this->postJson('/api/onboarding/brand', [
            'name' => 'My Better Brand',
            'phone' => '0712345678',
            'location' => 'Alger',
            'links' => ['https://tiktok.com/@mybrand'],
            'industries' => [$fashion->id],
        ])->assertStatus(200)
            ->assertJsonFragment(['name' => 'My Better Brand']);

        $this->assertDatabaseCount('brand_profiles', 1);
        $this->assertDatabaseHas('brand_profiles', [
            'user_id' => $user->id,
            'name' => 'My Better Brand',
            'location' => 'Alger',
        ]);
        $this->assertDatabaseMissing('social_links', [
            'user_id' => $user->id,
            'url' => 'https://instagram.com/mybrand',
        ]);
        $this->assertDatabaseHas('social_links', [
            'user_id' => $user->id,
            'url' => 'https://tiktok.com/@mybrand',
        ]);
    }

    public function test_verified_creator_user_can_create_creator_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);
        $category = Category::create(['name' => 'Fashion']);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/creator', [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'phone' => '0612345678',
            'links' => ['https://instagram.com/johndoe'],
            'categories' => [$category->id],
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['first_name' => 'John']);

        $this->assertDatabaseHas('creator_profiles', [
            'user_id' => $user->id,
            'first_name' => 'John',
        ]);

        $this->assertNotNull($user->fresh()->onboarding_completed_at);
    }

    public function test_creator_onboarding_can_be_submitted_again_to_update_profile(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);
        $fashion = Category::create(['name' => 'Fashion']);
        $travel = Category::create(['name' => 'Travel']);

        $this->actingAs($user);

        $this->postJson('/api/onboarding/creator', [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'phone' => '0612345678',
            'links' => ['https://instagram.com/johndoe'],
            'categories' => [$fashion->id],
        ])->assertStatus(201);

        $this->postJson('/api/onboarding/creator', [
            'first_name' => 'Jane',
            'last_name' => 'Doe',
            'phone' => '0712345678',
            'links' => ['https://youtube.com/@janedoe'],
            'categories' => [$travel->id],
        ])->assertStatus(200)
            ->assertJsonFragment(['first_name' => 'Jane']);

        $this->assertDatabaseCount('creator_profiles', 1);
        $this->assertDatabaseHas('creator_profiles', [
            'user_id' => $user->id,
            'first_name' => 'Jane',
            'phone' => '0712345678',
        ]);
        $this->assertDatabaseMissing('social_links', [
            'user_id' => $user->id,
            'url' => 'https://instagram.com/johndoe',
        ]);
        $this->assertDatabaseHas('social_links', [
            'user_id' => $user->id,
            'url' => 'https://youtube.com/@janedoe',
        ]);
        $this->assertDatabaseMissing('user_categories', [
            'user_id' => $user->id,
            'category_id' => $fashion->id,
        ]);
        $this->assertDatabaseHas('user_categories', [
            'user_id' => $user->id,
            'category_id' => $travel->id,
        ]);
    }

    public function test_creator_onboarding_requires_social_links(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);
        $category = Category::create(['name' => 'Fashion']);

        $this->actingAs($user);

        $response = $this->postJson('/api/onboarding/creator', [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'phone' => '0612345678',
            'categories' => [$category->id],
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('links');
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
