<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('push_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('provider', 20)->default('fcm');
            $table->string('platform', 20)->nullable();
            $table->string('device_id')->nullable();
            $table->string('app_version', 50)->nullable();
            $table->char('token_hash', 64)->unique();
            $table->text('token');
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'provider']);
            $table->index(['provider', 'platform']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('push_device_tokens');
    }
};
