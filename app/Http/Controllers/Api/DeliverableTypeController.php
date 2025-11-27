<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliverableType;
use Illuminate\Http\Request;

class DeliverableTypeController extends Controller
{
    public function index()
    {
        return DeliverableType::all();
    }
}
