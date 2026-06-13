<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageReadEvent;
use App\Events\NewMessageEvent;
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
        if (! $this->isParticipant($collaboration, $request->user()->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $this->markReadForUser($collaboration, $request->user(), true);

        return response()->json(
            $this->loadCollaborationResponse($collaboration, $request->user())
        );
    }

    public function messages(Request $request, Collaboration $collaboration)
    {
        if (! $this->isParticipant($collaboration, $request->user()->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'limit' => 'nullable|integer|min:1|max:50',
            'before_id' => 'nullable|integer|min:1',
        ]);

        $limit = $validated['limit'] ?? 30;

        $query = $collaboration->messages()
            ->with('sender')
            ->latest('id');

        if (! empty($validated['before_id'])) {
            $query->where('id', '<', $validated['before_id']);
        }

        $messages = $query->limit($limit + 1)->get();
        $hasMore = $messages->count() > $limit;

        if ($hasMore) {
            $messages = $messages->take($limit);
        }

        $messages = $messages->reverse()->values();

        return response()->json([
            'data' => $messages,
            'next_cursor' => $hasMore && $messages->isNotEmpty()
                ? $messages->first()->id
                : null,
            'has_more' => $hasMore,
        ]);
    }

    /**
     * Heartbeat — keeps presence alive while user stays in the chat screen.
     * Mobile app should call this every ~15 seconds.
     */
    public function heartbeat(Request $request, Collaboration $collaboration)
    {
        if (! $this->isParticipant($collaboration, $request->user()->id)) {
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
        if (! $this->isParticipant($collaboration, $request->user()->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $payload = $this->markReadForUser($collaboration, $request->user(), true);

        return response()->json($payload);
    }

    public function updateStatus(Request $request, Collaboration $collaboration)
    {
        // Only brand can complete or cancel, for simplicity
        if (! $this->isBrandOwner($collaboration, $request->user()->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:in_progress,completed,cancelled',
        ]);

        $updateData = ['status' => $validated['status']];
        if ($validated['status'] === 'completed' || $validated['status'] === 'cancelled') {
            $updateData['completed_at'] = now();
        }

        $collaboration->update($updateData);

        return response()->json(
            $this->loadCollaborationResponse($collaboration, $request->user())
        );
    }

    public function complete(Request $request, Collaboration $collaboration)
    {
        if (! $this->isBrandOwner($collaboration, $request->user()->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $collaboration->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json(
            $this->loadCollaborationResponse($collaboration, $request->user())
        );
    }

    public function sendMessage(Request $request, Collaboration $collaboration)
    {
        if (! $this->isParticipant($collaboration, $request->user()->id)) {
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

        // Update sender's presence/read state (they're actively in the chat).
        $user = $request->user();
        if ($user->id === $collaboration->brand_id) {
            $collaboration->update([
                'brand_last_seen_at' => now(),
                'brand_last_read_at' => now(),
            ]);
        } else {
            $collaboration->update([
                'creator_last_seen_at' => now(),
                'creator_last_read_at' => now(),
            ]);
        }

        $collaboration->messages()
            ->where('sender_id', '!=', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        // Broadcast to private channel (real-time delivery via WebSocket).
        broadcast(new NewMessageEvent($message->load('sender')))->toOthers();
        broadcast(new MessageReadEvent(
            $collaboration->fresh(),
            $user->id,
            now()->toJSON()
        ))->toOthers();

        // Smart notification for recipient
        $recipient = $user->id === $collaboration->brand_id
            ? $collaboration->creator
            : $collaboration->brand;

        // Layer 1: Skip if recipient is actively viewing the chat
        if (! $collaboration->fresh()->isUserViewing($recipient)) {
            // Layer 2: Throttle — only push if no recent push for this collab (2 min window)
            $throttleKey = "msg_push:{$recipient->id}:{$collaboration->id}";

            if (! \Illuminate\Support\Facades\Cache::has($throttleKey)) {
                // Mark throttle (expires in 2 minutes)
                \Illuminate\Support\Facades\Cache::put($throttleKey, true, 120);

                // Send push-only (no DB notification record — messages ≠ notifications)
                $route = ($recipient->isBrand() ? '/brand' : '/creator').'/collaboration-details/'.$collaboration->id;

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

    private function markReadForUser(Collaboration $collaboration, $user, bool $broadcast = false): array
    {
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

        $collaboration->messages()
            ->where('sender_id', '!=', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        $fresh = $collaboration->fresh();
        $payload = [
            'status' => 'ok',
            'collaboration_id' => $fresh->id,
            'reader_id' => $user->id,
            'read_at' => $now->toJSON(),
            'brand_last_read_at' => $fresh->brand_last_read_at?->toJSON(),
            'creator_last_read_at' => $fresh->creator_last_read_at?->toJSON(),
            'brand_last_seen_at' => $fresh->brand_last_seen_at?->toJSON(),
            'creator_last_seen_at' => $fresh->creator_last_seen_at?->toJSON(),
            'unread_count' => $fresh->unreadCountFor($user),
        ];

        if ($broadcast) {
            broadcast(new MessageReadEvent($fresh, $user->id, $now->toJSON()))->toOthers();
        }

        return $payload;
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

        $isExpectedDeliverable = $collaboration->announcement
            ->deliverables()
            ->where('deliverable_types.id', $validated['deliverable_type_id'])
            ->exists();

        if (! $isExpectedDeliverable) {
            return response()->json([
                'message' => "Ce livrable n'est pas demandé pour cette collaboration.",
            ], 422);
        }

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
            ['route' => '/brand/collaboration-details/'.$collaboration->id, 'params' => ['id' => $collaboration->id, 'tab' => 'deliverables']]
        );

        return response()->json($submission->load('deliverableType'), 201);
    }

    public function updateSubmissionStatus(Request $request, \App\Models\DeliverableSubmission $submission)
    {
        $collaboration = $submission->collaboration;

        // Only Brand can approve or reject
        if (! $this->isBrandOwner($collaboration, $request->user()->id)) {
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
            'deliverable_'.$validated['status'],
            "Livrable {$statusText}",
            "Votre livrable pour {$collaboration->announcement->title} a été {$statusText}.",
            ['route' => '/creator/collaboration-details/'.$collaboration->id, 'params' => ['id' => $collaboration->id, 'tab' => 'deliverables']]
        );

        return response()->json($submission->load('deliverableType'));
    }

    private function isParticipant(Collaboration $collaboration, int $userId): bool
    {
        return $collaboration->brand_id === $userId || $collaboration->creator_id === $userId;
    }

    private function isBrandOwner(Collaboration $collaboration, int $userId): bool
    {
        return $collaboration->brand_id === $userId;
    }

    private function loadCollaborationResponse(Collaboration $collaboration, $user): Collaboration
    {
        $collaboration = $collaboration->fresh([
            'announcement.category',
            'announcement.platforms',
            'announcement.deliverables',
            'announcement.influencerTier',
            'brand.brandProfile',
            'creator.creatorProfile',
            'application',
            'submissions.deliverableType',
            'reviews' => fn ($query) => $query->published()->latest(),
            'reviews.reviewer.brandProfile',
            'reviews.reviewer.creatorProfile',
            'reviews.reviewedUser.brandProfile',
            'reviews.reviewedUser.creatorProfile',
        ]);

        $collaboration->unread_count = $collaboration->unreadCountFor($user);
        $collaboration->current_user_review = $collaboration->reviews()
            ->where('reviewer_id', $user->id)
            ->with([
                'reviewer.brandProfile',
                'reviewer.creatorProfile',
                'reviewedUser.brandProfile',
                'reviewedUser.creatorProfile',
            ])
            ->first();

        if ($collaboration->brand) {
            $collaboration->brand->setAttribute(
                'reputation_summary',
                $collaboration->brand->reputationSummary()
            );
        }

        if ($collaboration->creator) {
            $collaboration->creator->setAttribute(
                'reputation_summary',
                $collaboration->creator->reputationSummary()
            );
        }

        return $collaboration;
    }
}
