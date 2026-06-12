<?php

namespace Tests\Feature;

use App\Enums\ApplicationStatus;
use App\Enums\UserType;
use App\Models\Announcement;
use App\Models\Application;
use App\Models\BrandProfile;
use App\Models\Category;
use App\Models\CreatorProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PriorityOneApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_brand_can_browse_onboarded_creators(): void
    {
        $brand = User::factory()->create(['type' => UserType::BRAND]);
        $fashion = Category::create(['name' => 'Fashion']);
        $tech = Category::create(['name' => 'Tech']);

        $creator = User::factory()->create([
            'type' => UserType::CREATOR,
            'onboarding_completed_at' => now(),
        ]);
        CreatorProfile::create([
            'user_id' => $creator->id,
            'first_name' => 'Amina',
            'last_name' => 'Creator',
            'nickname' => 'amina',
            'phone' => '0612345678',
        ]);
        $creator->categories()->attach($fashion->id);

        $hiddenCreator = User::factory()->create(['type' => UserType::CREATOR]);
        CreatorProfile::create([
            'user_id' => $hiddenCreator->id,
            'first_name' => 'Hidden',
            'last_name' => 'Creator',
            'phone' => '0612345678',
        ]);
        $hiddenCreator->categories()->attach($tech->id);

        $this->actingAs($brand);

        $this->getJson('/api/creators?search=Amina&category_id=' . $fashion->id)
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $creator->id)
            ->assertJsonPath('0.creator_profile.first_name', 'Amina')
            ->assertJsonPath('0.categories.0.name', 'Fashion');
    }

    public function test_creator_cannot_browse_creator_discovery_endpoint(): void
    {
        $creator = User::factory()->create(['type' => UserType::CREATOR]);

        $this->actingAs($creator);

        $this->getJson('/api/creators')->assertForbidden();
    }

    public function test_application_show_is_available_to_owner_and_brand(): void
    {
        [$brand, $creator, $application] = $this->createApplicationFixture();

        $this->actingAs($brand);
        $this->getJson("/api/applications/{$application->id}")
            ->assertOk()
            ->assertJsonPath('id', $application->id)
            ->assertJsonPath('user.creator_profile.first_name', 'Nadia')
            ->assertJsonPath('announcement.user.brand_profile.name', 'Brand Co');

        $this->actingAs($creator);
        $this->getJson("/api/applications/{$application->id}")
            ->assertOk()
            ->assertJsonPath('id', $application->id);
    }

    public function test_application_show_rejects_outsiders(): void
    {
        [, , $application] = $this->createApplicationFixture();
        $outsider = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($outsider);

        $this->getJson("/api/applications/{$application->id}")
            ->assertForbidden();
    }

    public function test_announcement_show_includes_current_creator_application(): void
    {
        [, $creator, $application] = $this->createApplicationFixture();

        $this->actingAs($creator);

        $this->getJson("/api/announcements/{$application->announcement_id}")
            ->assertOk()
            ->assertJsonPath('current_user_application.id', $application->id)
            ->assertJsonPath('current_user_application.status', ApplicationStatus::PENDING->value);
    }

    public function test_creator_cannot_apply_twice_to_same_announcement(): void
    {
        [, $creator, $application] = $this->createApplicationFixture();

        $this->actingAs($creator);

        $this->postJson("/api/announcements/{$application->announcement_id}/apply", [
            'message' => 'Je veux encore postuler',
            'proposed_budget' => 175,
        ])
            ->assertStatus(409)
            ->assertJsonPath('message', 'Vous avez déjà postulé à cette annonce.');

        $this->assertSame(
            1,
            Application::where('announcement_id', $application->announcement_id)
                ->where('user_id', $creator->id)
                ->count()
        );
    }

    private function createApplicationFixture(): array
    {
        $brand = User::factory()->create(['type' => UserType::BRAND]);
        BrandProfile::create([
            'user_id' => $brand->id,
            'name' => 'Brand Co',
            'phone' => '0612345678',
            'location' => 'Alger',
        ]);

        $creator = User::factory()->create([
            'type' => UserType::CREATOR,
            'onboarding_completed_at' => now(),
        ]);
        CreatorProfile::create([
            'user_id' => $creator->id,
            'first_name' => 'Nadia',
            'last_name' => 'Creator',
            'phone' => '0612345678',
        ]);

        $category = Category::create(['name' => 'Tech']);
        $announcement = Announcement::create([
            'user_id' => $brand->id,
            'category_id' => $category->id,
            'title' => 'Campagne test',
            'description' => 'Description test',
            'budget_min' => 100,
            'budget_max' => 200,
            'deadline' => now()->addWeek()->toDateString(),
        ]);

        $application = Application::create([
            'announcement_id' => $announcement->id,
            'user_id' => $creator->id,
            'message' => 'Je suis disponible',
            'proposed_budget' => 150,
            'status' => ApplicationStatus::PENDING->value,
        ]);

        return [$brand, $creator, $application];
    }
}
