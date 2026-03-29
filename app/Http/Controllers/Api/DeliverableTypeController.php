<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliverableType;
use Illuminate\Http\Request;

class DeliverableTypeController extends Controller
{
    public function index(Request $request)
    {
        $query = DeliverableType::query();
        if ($request->has('platform_id')) {
            $query->where('platform_id', $request->platform_id);
        }
        return $query->get();
    }
}
