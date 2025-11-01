<?php

namespace App\Http\Controllers\Onboarding;

use App\Enums\UserType;
use App\Http\Controllers\Controller;
use App\Models\BrandProfile;
use App\Models\CreatorProfile;
use Illuminate\Http\Request;

class OnboardingController extends Controller
{
    public function storeBrandProfile(Request $request)
    {
        $user = $request->user();

        if ($user->type !== UserType::BRAND) {
            return response()->json(['message' => 'You are not a brand.'], 403);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'website' => ['nullable', 'url'],
            'logo' => ['nullable', 'string'],
        ]);

        $brandProfile = BrandProfile::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'description' => data_get($validated, 'description'),
            'website' => data_get($validated, 'website'),
            'logo' => data_get($validated, 'logo'),
        ]);

        $user->update(['onboarding_completed_at' => now()]);

        return response()->json($brandProfile, 201);
    }

    public function storeCreatorProfile(Request $request)
    {
        $user = $request->user();

        if ($user->type !== UserType::CREATOR) {
            return response()->json(['message' => 'You are not a creator.'], 403);
        }

        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'bio' => ['nullable', 'string'],
            'instagram_handle' => ['nullable', 'string'],
            'tiktok_handle' => ['nullable', 'string'],
            'profile_picture' => ['nullable', 'string'],
        ]);

        $creatorProfile = CreatorProfile::create([
            'user_id' => $user->id,
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'bio' => data_get($validated, 'bio'),
            'instagram_handle' => data_get($validated, 'instagram_handle'),
            'tiktok_handle' => data_get($validated, 'tiktok_handle'),
            'profile_picture' => data_get($validated, 'profile_picture'),
        ]);

        $user->update(['onboarding_completed_at' => now()]);

        return response()->json($creatorProfile, 201);
    }
}
