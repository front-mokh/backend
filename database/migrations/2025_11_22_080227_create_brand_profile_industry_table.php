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
        Schema::create('brand_profile_industry', function (Blueprint $table) {
            $table->foreignId('brand_profile_id')->constrained()->onDelete('cascade');
            $table->foreignId('industry_id')->constrained()->onDelete('cascade');
            $table->primary(['brand_profile_id', 'industry_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('brand_profile_industry');
    }
};
