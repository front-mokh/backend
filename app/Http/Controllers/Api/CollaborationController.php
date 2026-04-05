<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Collaboration;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class CollaborationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        
        $query = Collaboration::query()
            ->with(['announcement', 'brand.brandProfile', 'creator.creatorProfile', 'application']);

        if ($user->isBrand()) {
            $query->where('brand_id', $user->id);
        } else {
            $query->where('creator_id', $user->id);
        }

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $collaborations = $query->latest('updated_at')->get();

        // Append unread_count for each collaboration
        $collaborations->each(function ($collaboration) use ($user) {
            $collaboration->unread_count = $collaboration->unreadCountFor($user);
        });

        return $collaborations;
    }

    public function show(Request $request, Collaboration $collaboration)
    {
        // Authorize user is part of the collaboration
        if ($collaboration->brand_id !== $request->user()->id && $collaboration->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Update presence + mark messages as read (user opened the chat)
        $user = $request->user();
        $now = now();

        if ($user->id === $collaboration->brand_id) {
            $collaboration->update([
                'brand_last_seen_at' => $now,
                'brand_last_read_at' => $now,
            ]);
        } else {
            $collaboration->update([
                'creator_last_seen_at' => $now,
                'creator_last_read_at' => $now,
            ]);
        }

        // Load relationships
        $collaboration->load([
            'announcement.deliverables', 
            'brand.brandProfile', 
            'creator.creatorProfile', 
            'application',
            'messages.sender',
            'submissions.deliverableType'
        ]);

        return response()->json($collaboration);
    }

    /**
     * Heartbeat — keeps presence alive while user stays in the chat screen.
     * Mobile app should call this every ~15 seconds.
     */
    public function heartbeat(Request $request, Collaboration $collaboration)
    {
        if ($collaboration->brand_id !== $request->user()->id && $collaboration->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = $request->user();
        $now = now();

        if ($user->id === $collaboration->brand_id) {
            $collaboration->update(['brand_last_seen_at' => $now]);
        } else {
            $collaboration->update(['creator_last_seen_at' => $now]);
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Mark messages as read — updates last_read_at for the user.
     */
    public function markAsRead(Request $request, Collaboration $collaboration)
    {
        if ($collaboration->brand_id !== $request->user()->id && $collaboration->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = $request->user();
        $now = now();

        if ($user->id === $collaboration->brand_id) {
            $collaboration->update(['brand_last_read_at' => $now]);
        } else {
            $collaboration->update(['creator_last_read_at' => $now]);
        }

        return response()->json(['status' => 'ok']);
    }

    public function updateStatus(Request $request, Collaboration $collaboration)
    {
        // Only brand can complete or cancel, for simplicity
        if ($request->user()->id !== $collaboration->brand_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:in_progress,completed,cancelled'
        ]);

        $updateData = ['status' => $validated['status']];
        if ($validated['status'] === 'completed' || $validated['status'] === 'cancelled') {
            $updateData['completed_at'] = now();
        }

        $collaboration->update($updateData);

        return response()->json($collaboration);
    }

    public function sendMessage(Request $request, Collaboration $collaboration)
    {
        if ($collaboration->brand_id !== $request->user()->id && $collaboration->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'content' => 'required_without:attachment|string|nullable',
            'attachment' => 'nullable|file|max:10240', // 10MB
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('messages', 'public');
        }

        $message = $collaboration->messages()->create([
            'sender_id' => $request->user()->id,
            'content' => $validated['content'] ?? null,
            'attachment' => $attachmentPath,
        ]);

        // Broadcast to private channel (real-time delivery via WebSocket)
        broadcast(new \App\Events\NewMessageEvent($message->load('sender')))->toOthers();

        // Update sender's presence (they're actively in the chat)
        $user = $request->user();
        if ($user->id === $collaboration->brand_id) {
            $collaboration->update(['brand_last_seen_at' => now()]);
        } else {
            $collaboration->update(['creator_last_seen_at' => now()]);
        }

        // Smart notification for recipient
        $recipient = $user->id === $collaboration->brand_id
            ? $collaboration->creator
            : $collaboration->brand;

        // Layer 1: Skip if recipient is actively viewing the chat
        if (!$collaboration->fresh()->isUserViewing($recipient)) {
            // Layer 2: Throttle — only push if no recent push for this collab (2 min window)
            $throttleKey = "msg_push:{$recipient->id}:{$collaboration->id}";

            if (!\Illuminate\Support\Facades\Cache::has($throttleKey)) {
                // Mark throttle (expires in 2 minutes)
                \Illuminate\Support\Facades\Cache::put($throttleKey, true, 120);

                // Send push-only (no DB notification record — messages ≠ notifications)
                $route = ($recipient->isBrand() ? '/brand' : '/creator') . '/collaboration-details/' . $collaboration->id;

                NotificationService::sendPushOnly(
                    $recipient,
                    'Nouveau message',
                    "Vous avez reçu un nouveau message de {$user->display_name}.",
                    ['route' => $route, 'params' => ['id' => $collaboration->id, 'tab' => 'messages']]
                );
            }
        }

        return response()->json($message->load('sender'), 201);
    }

    public function submitDeliverable(Request $request, Collaboration $collaboration)
    {
        // Only creator can submit
        if ($request->user()->id !== $collaboration->creator_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'deliverable_type_id' => 'required|exists:deliverable_types,id',
            'url' => 'nullable|url',
            'attachment' => 'nullable|file|max:20480', // 20MB
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('submissions', 'public');
        }

        $submission = $collaboration->submissions()->create([
            'deliverable_type_id' => $validated['deliverable_type_id'],
            'url' => $validated['url'] ?? null,
            'attachment' => $attachmentPath,
            'status' => 'submitted',
        ]);

        // Notify Brand (deliverables ARE notifications — keep DB record)
        NotificationService::send(
            $collaboration->brand,
            'deliverable_submitted',
            'Nouveau livrable',
            "{$request->user()->display_name} a soumis un nouveau livrable pour {$collaboration->announcement->title}.",
            ['route' => '/brand/collaboration-details/' . $collaboration->id, 'params' => ['id' => $collaboration->id, 'tab' => 'deliverables']]
        );

        return response()->json($submission->load('deliverableType'), 201);
    }

    public function updateSubmissionStatus(Request $request, \App\Models\DeliverableSubmission $submission)
    {
        $collaboration = $submission->collaboration;
        
        // Only Brand can approve or reject
        if ($request->user()->id !== $collaboration->brand_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:approved,rejected',
            'feedback' => 'nullable|string',
        ]);

        $submission->update($validated);

        // Notify Creator (deliverables ARE notifications — keep DB record)
        $statusText = $validated['status'] === 'approved' ? 'approuvé' : 'refusé';
        NotificationService::send(
            $collaboration->creator,
            'deliverable_' . $validated['status'],
            "Livrable {$statusText}",
            "Votre livrable pour {$collaboration->announcement->title} a été {$statusText}.",
            ['route' => '/creator/collaboration-details/' . $collaboration->id, 'params' => ['id' => $collaboration->id, 'tab' => 'deliverables']]
        );

        return response()->json($submission);
    }
}
