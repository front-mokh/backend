<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('collaboration.{id}', function ($user, $id) {
    $collaboration = \App\Models\Collaboration::find($id);
    if (!$collaboration) return false;
    
    return $user->id === $collaboration->brand_id || $user->id === $collaboration->creator_id;
});
