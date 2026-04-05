<?php

namespace App\Http\Controllers\Api;

use App\Enums\ApplicationStatus;
use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Announcement;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class ApplicationController extends Controller
{
    public function store(Request $request, Announcement $announcement)
    {
        if (!$request->user()->isCreator()) {
            return response()->json(['message' => 'Only creators can apply'], 403);
        }

        // Check if already applied
        if ($announcement->applications()->where('user_id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'You have already applied to this announcement'], 400);
        }

        // Block apply if announcement is closed or expired
        if ($announcement->status !== 'open') {
            return response()->json(['message' => 'Cette annonce est clôturée et n\'accepte plus de candidatures.'], 403);
        }
        if ($announcement->deadline && $announcement->deadline->isPast()) {
            return response()->json(['message' => 'La date limite pour postuler à cette annonce est dépassée.'], 403);
        }

        $validated = $request->validate([
            'message' => 'required|string',
            'proposed_budget' => 'required|integer|min:0',
        ]);

        $application = $announcement->applications()->create([
            'user_id' => $request->user()->id,
            'message' => $validated['message'],
            'proposed_budget' => $validated['proposed_budget'],
            'status' => ApplicationStatus::PENDING->value,
        ]);

        // Notify Brand
        $nickname = $request->user()->display_name;
        NotificationService::send(
            $announcement->user,
            'new_candidature',
            'Nouvelle candidature',
            "{$nickname} a postulé à votre annonce {$announcement->title}.",
            ['route' => '/brand/application-details/' . $application->id . '?announcementId=' . $announcement->id, 'params' => ['id' => $application->id, 'announcementId' => $announcement->id]]
        );

        return response()->json($application, 201);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->isBrand()) {
            // Brands see applications for their announcements
            $query = Application::query()
                ->whereHas('announcement', function ($q) use ($user) {
                    $q->where('user_id', $user->id);
                })
                ->with(['user.creatorProfile', 'user.socialLinks', 'user.categories', 'announcement']);

            if ($request->has('announcement_id')) {
                $query->where('announcement_id', $request->announcement_id);
            }

            if ($request->has('status') && $request->status !== 'all') {
                $query->where('status', $request->status);
            }

            return $query->latest()->get(); // Return all for now, pagination can be added later if needed
        } else {
            // Creators see their own applications
            return Application::query()
                ->where('user_id', $user->id)
                ->with(['announcement.user.brandProfile'])
                ->latest()
                ->get();
        }
    }


    public function accept(Request $request, Application $application)
    {
         if ($request->user()->id !== $application->announcement->user_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $application->update(['status' => ApplicationStatus::ACCEPTED->value]);

        // Create the collaboration workspace
        $collaboration = \App\Models\Collaboration::firstOrCreate(
            ['application_id' => $application->id],
            [
                'announcement_id' => $application->announcement_id,
                'brand_id' => $application->announcement->user_id,
                'creator_id' => $application->user_id,
                'status' => 'in_progress',
            ]
        );

        // Notify Creator
        NotificationService::send(
            $application->user,
            'candidature_accepted',
            'Félicitations !',
            "Votre candidature pour {$application->announcement->title} a été acceptée.",
            ['route' => '/creator/collaboration-details/' . $collaboration->id, 'params' => ['id' => $collaboration->id]]
        );

        return response()->json($application);
    }

    public function reject(Request $request, Application $application)
    {
         if ($request->user()->id !== $application->announcement->user_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $application->update(['status' => ApplicationStatus::REJECTED->value]);

        // Notify Creator
        NotificationService::send(
            $application->user,
            'candidature_rejected',
            'Candidature refusée',
            "Votre candidature pour {$application->announcement->title} n'a pas été retenue.",
            ['route' => '/creator/applications']
        );

        return response()->json($application);
    }
}
