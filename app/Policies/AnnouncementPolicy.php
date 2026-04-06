<?php

namespace App\Policies;

use App\Models\Announcement;
use App\Models\User;
use App\Models\Admin;

class AnnouncementPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User|Admin $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User|Admin $user, Announcement $announcement): bool
    {
        return true;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User|Admin $user): bool
    {
        return true; // Any authenticated user can potentially create, further logic like ensuring they are a brand can go here or in middleware.
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User|Admin $user, Announcement $announcement): bool
    {
        if ($user instanceof Admin) {
            return true; // Admins can update any
        }
        return $user->id === $announcement->user_id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User|Admin $user, Announcement $announcement): bool
    {
        if ($user instanceof Admin) {
            return true; // Admins can delete any
        }
        return $user->id === $announcement->user_id;
    }
}
