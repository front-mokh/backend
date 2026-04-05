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
        Schema::table('collaborations', function (Blueprint $table) {
            $table->timestamp('brand_last_seen_at')->nullable();
            $table->timestamp('creator_last_seen_at')->nullable();
            $table->timestamp('brand_last_read_at')->nullable();
            $table->timestamp('creator_last_read_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('collaborations', function (Blueprint $table) {
            $table->dropColumn([
                'brand_last_seen_at',
                'creator_last_seen_at',
                'brand_last_read_at',
                'creator_last_read_at',
            ]);
        });
    }
};
