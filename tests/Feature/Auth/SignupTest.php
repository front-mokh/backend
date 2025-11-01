<?php

namespace Tests\Feature\Auth;

use App\Enums\UserType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SignupTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_signup_as_brand(): void
    {
        $response = $this->postJson('/api/signup', [
            'email' => 'brand@example.com',
            'password' => 'password',
            'type' => UserType::BRAND->value,
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['email' => 'brand@example.com']);

        $this->assertDatabaseHas('users', [
            'email' => 'brand@example.com',
        ]);
    }

    public function test_user_can_signup_as_creator(): void
    {
        $response = $this->postJson('/api/signup', [
            'email' => 'creator@example.com',
            'password' => 'password',
            'type' => UserType::CREATOR->value,
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['email' => 'creator@example.com']);

        $this->assertDatabaseHas('users', [
            'email' => 'creator@example.com',
        ]);
    }

    public function test_signup_requires_email(): void
    {
        $response = $this->postJson('/api/signup', [
            'password' => 'password',
            'type' => UserType::BRAND->value,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }

    public function test_signup_requires_password(): void
    {
        $response = $this->postJson('/api/signup', [
            'email' => 'test@example.com',
            'type' => UserType::BRAND->value,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    public function test_signup_requires_type(): void
    {
        $response = $this->postJson('/api/signup', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('type');
    }

    public function test_signup_requires_valid_type(): void
    {
        $response = $this->postJson('/api/signup', [
            'email' => 'test@example.com',
            'password' => 'password',
            'type' => 'invalid-type',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('type');
    }

    public function test_signup_email_is_unique(): void
    {
        User::factory()->create(['email' => 'existing@example.com']);

        $response = $this->postJson('/api/signup', [
            'email' => 'existing@example.com',
            'password' => 'password',
            'type' => UserType::BRAND->value,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }
}
