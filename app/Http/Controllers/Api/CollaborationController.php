<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Collaboration;
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

        return $query->latest('updated_at')->get();
    }

    public function show(Request $request, Collaboration $collaboration)
    {
        // Authorize user is part of the collaboration
        if ($collaboration->brand_id !== $request->user()->id && $collaboration->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
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

        return response()->json($submission);
    }
}
