<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserType;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        $user->load([
            'brandProfile.industries',
            'creatorProfile',
            'socialLinks',
            'categories'
        ]);

        return $user;
    }

    public function creators(Request $request)
    {
        if (!$request->user()->isBrand()) {
            return response()->json(['message' => 'Only brands can browse creators'], 403);
        }

        $query = User::query()
            ->where('type', UserType::CREATOR->value)
            ->whereNotNull('onboarding_completed_at')
            ->whereHas('creatorProfile')
            ->with(['creatorProfile', 'socialLinks', 'categories']);

        if ($request->filled('category_id') && $request->category_id !== 'all') {
            $query->whereHas('categories', function ($categoryQuery) use ($request) {
                $categoryQuery->where('categories.id', $request->category_id);
            });
        }

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($creatorQuery) use ($search) {
                $creatorQuery
                    ->where('email', 'like', "%{$search}%")
                    ->orWhereHas('creatorProfile', function ($profileQuery) use ($search) {
                        $profileQuery
                            ->where('first_name', 'like', "%{$search}%")
                            ->orWhere('last_name', 'like', "%{$search}%")
                            ->orWhere('nickname', 'like', "%{$search}%")
                            ->orWhere('bio', 'like', "%{$search}%");
                    })
                    ->orWhereHas('categories', function ($categoryQuery) use ($search) {
                        $categoryQuery->where('name', 'like', "%{$search}%");
                    });
            });
        }

        return $query
            ->latest('updated_at')
            ->limit(100)
            ->get();
    }
}
