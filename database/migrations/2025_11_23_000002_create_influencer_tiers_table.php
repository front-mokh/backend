<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('influencer_tiers', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Nano, Micro, etc.
            $table->integer('min_followers')->nullable();
            $table->integer('max_followers')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('influencer_tiers');
    }
};
