<?php

namespace App\Http\Controllers\Onboarding;

use App\Enums\UserType;
use App\Http\Controllers\Controller;
use App\Models\BrandProfile;
use App\Models\CreatorProfile;
use App\Models\SocialLink;
use App\Models\Category;
use Illuminate\Http\Request;

class OnboardingController extends Controller
{
    public function storeBrandProfile(Request $request)
    {
        $user = $request->user();

        if ($user->type !== UserType::BRAND) {
            return response()->json(['message' => 'Vous n\'êtes pas une marque.'], 403);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'regex:/^0[0-9]{9}$/'],
            'location' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'website' => ['nullable', 'url'],
            'logo' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:2048'],
            'links' => ['required', 'array', 'min:1', 'max:6'],
            'links.*' => ['required', 'url'],
            'industries' => ['required', 'array', 'min:1', 'max:3'],
            'industries.*' => ['required', 'exists:industries,id'],
        ], [
            'name.required' => 'Le nom est obligatoire.',
            'name.string' => 'Le nom doit être une chaîne de caractères.',
            'name.max' => 'Le nom ne doit pas dépasser :max caractères.',
            'phone.required' => 'Le numéro de téléphone est obligatoire.',
            'phone.string' => 'Le numéro de téléphone doit être une chaîne de caractères.',
            'phone.regex' => 'Le numéro de téléphone doit commencer par 0 et contenir 10 chiffres.',
            'location.required' => 'L\'adresse est obligatoire.',
            'location.string' => 'L\'adresse doit être une chaîne de caractères.',
            'location.max' => 'L\'adresse ne doit pas dépasser :max caractères.',
            'description.string' => 'La description doit être une chaîne de caractères.',
            'website.url' => 'Le site web doit être une URL valide.',
            'logo.image' => 'Le fichier doit être une image.',
            'logo.mimes' => 'Le logo doit être au format JPEG, PNG, JPG ou WebP.',
            'logo.max' => 'Le logo ne doit pas dépasser 2 Mo.',
            'links.required' => 'Au moins un lien social est requis.',
            'links.array' => 'Les liens sociaux doivent être un tableau.',
            'links.min' => 'Au moins :min lien social est requis.',
            'links.max' => 'Maximum :max liens sociaux sont autorisés.',
            'links.*.required' => 'Chaque lien social est obligatoire.',
            'links.*.url' => 'Chaque lien social doit être une URL valide.',
            'industries.required' => 'Au moins une industrie est requise.',
            'industries.array' => 'Les industries doivent être un tableau.',
            'industries.min' => 'Au moins :min industrie est requise.',
            'industries.max' => 'Maximum :max industries sont autorisées.',
            'industries.*.required' => 'Chaque industrie est obligatoire.',
            'industries.*.exists' => 'L\'industrie sélectionnée n\'est pas valide.',
        ]);

        $logoPath = null;
        if ($request->hasFile('logo')) {
            $logoPath = $request->file('logo')->store('logos', 'public');
        }

        $brandProfile = BrandProfile::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'location' => $validated['location'],
            'description' => data_get($validated, 'description'),
            'website' => data_get($validated, 'website'),
            'logo' => $logoPath,
        ]);

        foreach ($validated['links'] as $linkUrl) {
            $user->socialLinks()->create(['url' => $linkUrl]);
        }

        $brandProfile->industries()->attach($validated['industries']);

        $user->update(['onboarding_completed_at' => now()]);

        return response()->json($brandProfile, 201);
    }

    public function storeCreatorProfile(Request $request)
    {
        $user = $request->user();

        if ($user->type !== UserType::CREATOR) {
            return response()->json(['message' => 'Vous n\'êtes pas un créateur.'], 403);
        }

        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'phone' => [
                'required',
                'string',
                'regex:/^0[567][0-9]{8}$/'
            ],
            'nickname' => ['nullable', 'string', 'max:255'],
            'bio' => ['nullable', 'string'],
            'profile_picture' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:2048'], // 2MB max            'links' => ['required', 'array', 'min:1', 'max:6'],
            'links.*' => ['required', 'url'],
            'categories' => ['required', 'array', 'min:1', 'max:3'],
            'categories.*' => ['required', 'exists:categories,id'],
        ], [
            // French error messages for creator profile
            'first_name.required' => 'Le prénom est obligatoire.',
            'first_name.string' => 'Le prénom doit être une chaîne de caractères.',
            'first_name.max' => 'Le prénom ne doit pas dépasser :max caractères.',
            'last_name.required' => 'Le nom de famille est obligatoire.',
            'last_name.string' => 'Le nom de famille doit être une chaîne de caractères.',
            'last_name.max' => 'Le nom de famille ne doit pas dépasser :max caractères.',
            'phone.required' => 'Le numéro de téléphone est obligatoire.',
            'phone.string' => 'Le numéro de téléphone doit être une chaîne de caractères.',
            'phone.regex' => 'Le numéro de téléphone doit commencer par 05, 06 ou 07 et contenir 10 chiffres.',
            'nickname.string' => 'Le surnom doit être une chaîne de caractères.',
            'nickname.max' => 'Le surnom ne doit pas dépasser :max caractères.',
            'bio.string' => 'La biographie doit être une chaîne de caractères.',
            'profile_picture.string' => 'L\'image de profil doit être une chaîne de caractères.',

            'links.required' => 'Au moins un lien social est requis.',
            'links.array' => 'Les liens sociaux doivent être un tableau.',
            'links.min' => 'Au moins :min lien social est requis.',
            'links.max' => 'Maximum :max liens sociaux sont autorisés.',
            'links.*.required' => 'Chaque lien social est obligatoire.',
            'links.*.url' => 'Chaque lien social doit être une URL valide.',

            'categories.required' => 'Au moins une catégorie est requise.',
            'categories.array' => 'Les catégories doivent être un tableau.',
            'categories.min' => 'Au moins :min catégorie est requise.',
            'categories.max' => 'Maximum :max catégories sont autorisées.',
            'categories.*.required' => 'Chaque catégorie est obligatoire.',
            'categories.*.exists' => 'La catégorie sélectionnée n\'est pas valide.',
            'profile_picture.image' => 'Le fichier doit être une image.',
            'profile_picture.mimes' => 'L\'image doit être au format JPEG, PNG, JPG ou WebP.',
            'profile_picture.max' => 'L\'image ne doit pas dépasser 2 Mo.',
        ]);

        $profilePicturePath = null;
        if ($request->hasFile('profile_picture')) {
            $profilePicturePath = $request->file('profile_picture')
                ->store('profile-pictures', 'public');
        }

        $creatorProfile = CreatorProfile::create([
            'user_id' => $user->id,
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'phone' => $validated['phone'],
            'nickname' => data_get($validated, 'nickname'),
            'bio' => data_get($validated, 'bio'),
            'profile_picture' => $profilePicturePath,
        ]);

        // Store social links
        foreach ($validated['links'] as $linkUrl) {
            $user->socialLinks()->create(['url' => $linkUrl]);
        }

        // Attach categories
        $user->categories()->attach($validated['categories']);

        $user->update(['onboarding_completed_at' => now()]);

        return response()->json($creatorProfile, 201);
    }
}