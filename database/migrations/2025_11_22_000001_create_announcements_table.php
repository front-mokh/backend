<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Brand
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->string('title', 100);
            $table->text('description');
            $table->integer('budget_min');
            $table->integer('budget_max');
            $table->date('deadline'); // Deadline for applying
            $table->date('delivery_date')->nullable(); // Optional delivery date
            $table->integer('duration')->nullable(); // In days
            $table->string('target_audience')->nullable();
            $table->text('requirements')->nullable();
            $table->integer('min_followers')->nullable();
            $table->foreignId('influencer_tier_id')->nullable()->constrained()->onDelete('set null');
            $table->string('thumbnail')->nullable();
            $table->string('attachment')->nullable();
            $table->string('status')->default('open');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('announcements');
    }
};
