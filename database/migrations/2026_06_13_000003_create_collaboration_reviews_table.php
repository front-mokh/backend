<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('collaboration_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('collaboration_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reviewer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('reviewed_user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('reviewer_role', ['brand', 'creator']);
            $table->unsignedTinyInteger('rating');
            $table->unsignedTinyInteger('communication_rating')->nullable();
            $table->unsignedTinyInteger('quality_rating')->nullable();
            $table->unsignedTinyInteger('reliability_rating')->nullable();
            $table->unsignedTinyInteger('professionalism_rating')->nullable();
            $table->boolean('would_work_again')->nullable();
            $table->text('public_comment')->nullable();
            $table->enum('status', ['published', 'hidden'])->default('published');
            $table->timestamps();

            $table->unique(['collaboration_id', 'reviewer_id']);
            $table->index(['reviewed_user_id', 'status']);
            $table->index(['reviewer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('collaboration_reviews');
    }
};
