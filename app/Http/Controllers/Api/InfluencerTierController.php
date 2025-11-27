<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InfluencerTier;
use Illuminate\Http\Request;

class InfluencerTierController extends Controller
{
    public function index()
    {
        return InfluencerTier::all();
    }
}
