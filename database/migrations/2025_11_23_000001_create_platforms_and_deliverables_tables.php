<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platforms', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Instagram, TikTok, etc.
            $table->string('icon_name')->nullable(); // Ionicons name
            $table->timestamps();
        });

        Schema::create('deliverable_types', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Post, Story, Reel, etc.
            $table->string('icon_name')->nullable();
            $table->timestamps();
        });

        Schema::create('announcement_platform', function (Blueprint $table) {
            $table->id();
            $table->foreignId('announcement_id')->constrained()->onDelete('cascade');
            $table->foreignId('platform_id')->constrained()->onDelete('cascade');
            $table->timestamps();
        });

        Schema::create('announcement_deliverable', function (Blueprint $table) {
            $table->id();
            $table->foreignId('announcement_id')->constrained()->onDelete('cascade');
            $table->foreignId('deliverable_type_id')->constrained()->onDelete('cascade');
            $table->integer('quantity')->default(1);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcement_deliverable');
        Schema::dropIfExists('announcement_platform');
        Schema::dropIfExists('deliverable_types');
        Schema::dropIfExists('platforms');
    }
};
