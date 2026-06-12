<?php

namespace Tests\Feature;

use App\Enums\ApplicationStatus;
use App\Enums\UserType;
use App\Models\Announcement;
use App\Models\Application;
use App\Models\Category;
use App\Models\Collaboration;
use App\Models\Message;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChatReadTrackingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['broadcasting.default' => 'null']);
    }

    public function test_participant_can_mark_collaboration_messages_as_read(): void
    {
        [$brand, $creator, $collaboration] = $this->createCollaboration();

        $message = Message::create([
            'collaboration_id' => $collaboration->id,
            'sender_id' => $creator->id,
            'content' => 'Bonjour',
            'is_read' => false,
            'created_at' => now()->subMinute(),
            'updated_at' => now()->subMinute(),
        ]);

        $this->actingAs($brand);

        $response = $this->postJson("/api/collaborations/{$collaboration->id}/read");

        $response->assertOk()
            ->assertJson([
                'status' => 'ok',
                'collaboration_id' => $collaboration->id,
                'reader_id' => $brand->id,
                'unread_count' => 0,
            ]);

        $this->assertTrue($message->fresh()->is_read);
        $this->assertNotNull($collaboration->fresh()->brand_last_read_at);
        $this->assertNotNull($collaboration->fresh()->brand_last_seen_at);
    }

    public function test_collaboration_index_returns_live_unread_count(): void
    {
        [$brand, $creator, $collaboration] = $this->createCollaboration();

        Message::create([
            'collaboration_id' => $collaboration->id,
            'sender_id' => $creator->id,
            'content' => 'A lire',
            'is_read' => false,
            'created_at' => now()->subMinute(),
            'updated_at' => now()->subMinute(),
        ]);

        $this->actingAs($brand);

        $this->getJson('/api/collaborations')
            ->assertOk()
            ->assertJsonPath('0.unread_count', 1);

        $this->postJson("/api/collaborations/{$collaboration->id}/read")
            ->assertOk();

        $this->getJson('/api/collaborations')
            ->assertOk()
            ->assertJsonPath('0.unread_count', 0);
    }

    public function test_non_participant_cannot_mark_collaboration_as_read(): void
    {
        [, , $collaboration] = $this->createCollaboration();
        $outsider = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($outsider);

        $this->postJson("/api/collaborations/{$collaboration->id}/read")
            ->assertForbidden();
    }

    private function createCollaboration(): array
    {
        $brand = User::factory()->create(['type' => UserType::BRAND]);
        $creator = User::factory()->create(['type' => UserType::CREATOR]);
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
