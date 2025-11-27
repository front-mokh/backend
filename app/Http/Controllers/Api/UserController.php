<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
}
