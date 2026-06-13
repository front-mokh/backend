<?php

namespace Tests\Feature;

use App\Enums\ApplicationStatus;
use App\Enums\UserType;
use App\Models\Announcement;
use App\Models\Application;
use App\Models\BrandProfile;
use App\Models\Category;
use App\Models\Collaboration;
use App\Models\CreatorProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CollaborationReviewTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['broadcasting.default' => 'null']);
    }

    public function test_brand_can_review_creator_after_completed_collaboration(): void
    {
        [$brand, $creator, $collaboration] = $this->createCompletedCollaboration();

        $this->actingAs($brand);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 5,
            'communication_rating' => 4,
            'quality_rating' => 5,
            'reliability_rating' => 5,
            'professionalism_rating' => 5,
            'would_work_again' => true,
            'public_comment' => 'Excellent travail, livré dans les temps.',
        ])
            ->assertCreated()
            ->assertJsonPath('reviewer_id', $brand->id)
            ->assertJsonPath('reviewed_user_id', $creator->id)
            ->assertJsonPath('reviewer_role', 'brand')
            ->assertJsonPath('rating', 5)
            ->assertJsonPath('public_comment', 'Excellent travail, livré dans les temps.');

        $this->getJson("/api/collaborations/{$collaboration->id}")
            ->assertOk()
            ->assertJsonPath('current_user_review.rating', 5)
            ->assertJsonPath('reviews.0.reviewed_user_id', $creator->id)
            ->assertJsonPath('creator.reputation_summary.average_rating', 5)
            ->assertJsonPath('creator.reputation_summary.reviews_count', 1)
            ->assertJsonPath('creator.reputation_summary.completed_collaborations_count', 1);
    }

    public function test_creator_can_review_brand_after_completed_collaboration(): void
    {
        [$brand, $creator, $collaboration] = $this->createCompletedCollaboration();

        $this->actingAs($creator);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 4,
            'would_work_again' => true,
            'public_comment' => 'Brief clair et communication fluide.',
        ])
            ->assertCreated()
            ->assertJsonPath('reviewer_id', $creator->id)
            ->assertJsonPath('reviewed_user_id', $brand->id)
            ->assertJsonPath('reviewer_role', 'creator')
            ->assertJsonPath('rating', 4);
    }

    public function test_review_requires_completed_collaboration(): void
    {
        [$brand, , $collaboration] = $this->createCollaboration();

        $this->actingAs($brand);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 5,
        ])
            ->assertStatus(422)
            ->assertJsonPath(
                'message',
                'La collaboration doit être terminée avant de laisser un avis.'
            );
    }

    public function test_participant_cannot_review_same_collaboration_twice(): void
    {
        [$brand, , $collaboration] = $this->createCompletedCollaboration();

        $this->actingAs($brand);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 5,
        ])->assertCreated();

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 4,
        ])
            ->assertStatus(422)
            ->assertJsonPath(
                'message',
                'Vous avez déjà laissé un avis pour cette collaboration.'
            );
    }

    public function test_non_participant_cannot_review_collaboration(): void
    {
        [, , $collaboration] = $this->createCompletedCollaboration();
        $outsider = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($outsider);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 5,
        ])->assertForbidden();
    }

    public function test_creator_discovery_returns_reputation_summary(): void
    {
        [$brand, $creator, $collaboration] = $this->createCompletedCollaboration();

        $this->actingAs($brand);

        $this->postJson("/api/collaborations/{$collaboration->id}/reviews", [
            'rating' => 5,
            'would_work_again' => true,
        ])->assertCreated();

        $this->getJson('/api/creators')
            ->assertOk()
            ->assertJsonPath('0.id', $creator->id)
            ->assertJsonPath('0.reputation_summary.average_rating', 5)
            ->assertJsonPath('0.reputation_summary.reviews_count', 1)
            ->assertJsonPath('0.reputation_summary.would_work_again_rate', 100);
    }

    private function createCompletedCollaboration(): array
    {
        [$brand, $creator, $collaboration] = $this->createCollaboration();

        $collaboration->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return [$brand, $creator, $collaboration->fresh()];
    }

    private function createCollaboration(): array
    {
        $brand = User::factory()->create(['type' => UserType::BRAND]);
        $creator = User::factory()->create([
            'type' => UserType::CREATOR,
            'onboarding_completed_at' => now(),
        ]);
        $category = Category::create(['name' => 'Tech']);

        BrandProfile::create([
            'user_id' => $brand->id,
            'name' => 'Brand Test',
            'phone' => '0555000000',
            'location' => 'Alger',
        ]);

        CreatorProfile::create([
            'user_id' => $creator->id,
            'first_name' => 'Sara',
            'last_name' => 'Creator',
            'phone' => '0555111111',
            'nickname' => 'sara.creator',
            'bio' => 'Créatrice tech',
        ]);

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
            'status' => ApplicationStatus::ACCEPTED->value,
        ]);

        $collaboration = Collaboration::create([
            'application_id' => $application->id,
            'announcement_id' => $announcement->id,
            'brand_id' => $brand->id,
            'creator_id' => $creator->id,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        return [$brand, $creator, $collaboration];
    }
}
