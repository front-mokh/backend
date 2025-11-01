<?php

namespace App\Http\Controllers\Auth;

use App\Enums\UserType;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Enum;

class SignupController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'unique:users'],
            'password' => ['required', 'min:8'],
            'type' => ['required', new Enum(UserType::class)],
        ]);

        $user = User::create([
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'type' => $validated['type'],
        ]);

        event(new Registered($user));

        return response()->json([
            'message' => 'User created successfully. Please check your email for a verification link.',
            'user' => $user,
        ], 201);
    }
}
