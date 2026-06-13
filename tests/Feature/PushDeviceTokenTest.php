<?php

namespace Tests\Feature;

use App\Enums\UserType;
use App\Models\PushDeviceToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PushDeviceTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_update_fcm_push_token(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);

        $this->actingAs($user);

        $this->postJson('/api/push-tokens', [
            'token' => 'fcm-token-123',
            'provider' => 'fcm',
            'platform' => 'android',
            'device_id' => 'device-a',
            'app_version' => '1.0.0+1',
        ])
            ->assertCreated()
            ->assertJsonPath('message', 'Push token registered')
            ->assertJsonPath('device_token.provider', 'fcm')
            ->assertJsonPath('device_token.platform', 'android')
            ->assertJsonMissingPath('device_token.token');

        $this->assertDatabaseHas('push_device_tokens', [
            'user_id' => $user->id,
            'provider' => 'fcm',
            'platform' => 'android',
            'device_id' => 'device-a',
            'token_hash' => PushDeviceToken::hashToken('fcm-token-123'),
        ]);

        $this->postJson('/api/push-tokens', [
            'token' => 'fcm-token-123',
            'provider' => 'fcm',
            'platform' => 'ios',
            'device_id' => 'device-a',
        ])
            ->assertOk()
            ->assertJsonPath('device_token.platform', 'ios');

        $this->assertSame(1, PushDeviceToken::count());
        $this->assertDatabaseHas('push_device_tokens', [
            'token_hash' => PushDeviceToken::hashToken('fcm-token-123'),
            'platform' => 'ios',
        ]);
    }

    public function test_user_can_remove_current_push_token(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);
        PushDeviceToken::create([
            'user_id' => $user->id,
            'provider' => 'fcm',
            'platform' => 'android',
            'token' => 'token-to-delete',
            'token_hash' => PushDeviceToken::hashToken('token-to-delete'),
        ]);

        $this->actingAs($user);

        $this->deleteJson('/api/push-tokens', [
            'token' => 'token-to-delete',
        ])
            ->assertOk()
            ->assertJsonPath('deleted', true);

        $this->assertDatabaseMissing('push_device_tokens', [
            'token_hash' => PushDeviceToken::hashToken('token-to-delete'),
        ]);
    }

    public function test_push_token_registration_validates_provider_and_platform(): void
    {
        $user = User::factory()->create(['type' => UserType::BRAND]);

        $this->actingAs($user);

        $this->postJson('/api/push-tokens', [
            'token' => 'bad-token',
            'provider' => 'paid_vendor',
            'platform' => 'pager',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['provider', 'platform']);
    }

    public function test_legacy_expo_endpoint_still_registers_compatibility_token(): void
    {
        $user = User::factory()->create(['type' => UserType::CREATOR]);

        $this->actingAs($user);

        $this->postJson('/api/user/expo-push-token', [
            'token' => 'ExponentPushToken[legacy]',
            'platform' => 'android',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Push token registered');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'expo_push_token' => 'ExponentPushToken[legacy]',
        ]);
        $this->assertDatabaseHas('push_device_tokens', [
            'user_id' => $user->id,
            'provider' => 'expo',
            'platform' => 'android',
            'token_hash' => PushDeviceToken::hashToken('ExponentPushToken[legacy]'),
        ]);
    }
}
