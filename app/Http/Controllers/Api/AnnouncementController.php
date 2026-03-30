<?php

namespace App\Http\Controllers\Api;

use App\Enums\ProjectStatus;
use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Enum;
use Carbon\Carbon;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $query = Announcement::with(['category', 'platforms', 'deliverables', 'influencerTier'])
            ->withCount([
                'applications',
                'applications as applications_pending_count' => function ($query) {
                    $query->where('status', 'pending');
                },
                'applications as applications_accepted_count' => function ($query) {
                    $query->where('status', 'accepted');
                },
                'applications as applications_rejected_count' => function ($query) {
                    $query->where('status', 'rejected');
                },
            ]);

        if ($request->user()->isBrand()) {
            $query->where('user_id', $request->user()->id);
        } else {
            $query->where('status', ProjectStatus::OPEN)
                  ->where('deadline', '>=', Carbon::today());

            if ($request->has('category_id')) {
                $query->where('category_id', $request->category_id);
            }

            if ($request->has('min_budget')) {
                $query->where('budget_max', '>=', $request->min_budget);
            }

            if ($request->has('influencer_tier_id')) {
                $query->where('influencer_tier_id', $request->influencer_tier_id);
            }
        }

        return $query->latest()->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'required|exists:categories,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'budget_min' => 'required|numeric|min:0',
            'budget_max' => 'required|numeric|gte:budget_min',
            'deadline' => 'required|date|after:today',
            'delivery_date' => 'nullable|date|after:deadline',
            'duration' => 'nullable|integer|min:1',
            'target_audience' => 'nullable|string',
            'requirements' => 'nullable|string',
            'min_followers' => 'nullable|integer|min:0',
            'influencer_tier_id' => 'nullable|exists:influencer_tiers,id',
            'thumbnail' => 'nullable|image|max:2048',
            'attachment' => 'nullable|mimes:pdf|max:5120',
            'platforms' => 'nullable|array',
            'platforms.*' => 'exists:platforms,id',
            'deliverables' => 'nullable|array',
            'deliverables.*.id' => [
                'exists:deliverable_types,id',
                function ($attribute, $value, $fail) use ($request) {
                    $platforms = $request->input('platforms', []);
                    $deliverableType = \App\Models\DeliverableType::find($value);
                    if ($deliverableType && !in_array($deliverableType->platform_id, $platforms)) {
                        $fail('The requested deliverable type does not belong to any of the selected platforms.');
                    }
                },
            ],
            'deliverables.*.quantity' => 'integer|min:1',
        ]);

        if ($request->hasFile('thumbnail')) {
            $validated['thumbnail'] = $request->file('thumbnail')->store('announcements/thumbnails', 'public');
        }

        if ($request->hasFile('attachment')) {
            $validated['attachment'] = $request->file('attachment')->store('announcements/attachments', 'public');
        }

        $validated['user_id'] = $request->user()->id;

        $announcement = Announcement::create($validated);

        if (!empty($validated['platforms'])) {
            $announcement->platforms()->attach($validated['platforms']);
        }

        if (!empty($validated['deliverables'])) {
            foreach ($validated['deliverables'] as $deliverable) {
                $announcement->deliverables()->attach($deliverable['id'], ['quantity' => $deliverable['quantity']]);
            }
        }

        return $announcement->load(['category', 'platforms', 'deliverables', 'influencerTier']);
    }

    public function show(Announcement $announcement)
    {
        return $announcement->load(['category', 'platforms', 'deliverables', 'influencerTier'])
            ->loadCount([
                'applications',
                'applications as applications_pending_count' => function ($query) {
                    $query->where('status', 'pending');
                },
                'applications as applications_accepted_count' => function ($query) {
                    $query->where('status', 'accepted');
                },
                'applications as applications_rejected_count' => function ($query) {
                    $query->where('status', 'rejected');
                },
            ]);
    }

    public function update(Request $request, Announcement $announcement)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $announcement);

        $validated = $request->validate([
            'category_id' => 'sometimes|required|exists:categories,id',
            'title' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|required|string',
            'budget_min' => 'sometimes|required|numeric|min:0',
            'budget_max' => 'sometimes|required|numeric|gte:budget_min',
            'deadline' => 'sometimes|required|date',
            'delivery_date' => 'nullable|date',
            'duration' => 'nullable|integer|min:1',
            'target_audience' => 'nullable|string',
            'requirements' => 'nullable|string',
            'min_followers' => 'nullable|integer|min:0',
            'influencer_tier_id' => 'nullable|exists:influencer_tiers,id',
            'thumbnail' => 'nullable|image|max:2048',
            'attachment' => 'nullable|mimes:pdf|max:5120',
            'platforms' => 'nullable|array',
            'platforms.*' => 'exists:platforms,id',
            'deliverables' => 'nullable|array',
            'deliverables.*.id' => [
                'exists:deliverable_types,id',
                function ($attribute, $value, $fail) use ($request, $announcement) {
                    $platforms = $request->input('platforms', $announcement->platforms->pluck('id')->toArray());
                    $deliverableType = \App\Models\DeliverableType::find($value);
                    if ($deliverableType && !in_array($deliverableType->platform_id, $platforms)) {
                        $fail('The requested deliverable type does not belong to any of the selected platforms.');
                    }
                },
            ],
            'deliverables.*.quantity' => 'integer|min:1',
            'status' => ['sometimes', new Enum(ProjectStatus::class)],
        ]);

        if ($request->hasFile('thumbnail')) {
            if ($announcement->thumbnail) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($announcement->thumbnail);
            }
            $validated['thumbnail'] = $request->file('thumbnail')->store('announcements/thumbnails', 'public');
        }

        if ($request->hasFile('attachment')) {
            if ($announcement->attachment) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($announcement->attachment);
            }
            $validated['attachment'] = $request->file('attachment')->store('announcements/attachments', 'public');
        }

        $announcement->update($validated);

        if (array_key_exists('platforms', $validated)) {
            $announcement->platforms()->sync($validated['platforms'] ?? []);
        }

        if (array_key_exists('deliverables', $validated)) {
            $deliverableData = [];
            if (!empty($validated['deliverables'])) {
                foreach ($validated['deliverables'] as $deliverable) {
                    $deliverableData[$deliverable['id']] = ['quantity' => $deliverable['quantity']];
                }
            }
            $announcement->deliverables()->sync($deliverableData);
        }

        return $announcement->load(['category', 'platforms', 'deliverables', 'influencerTier'])->loadCount([
            'applications',
            'applications as applications_pending_count' => function ($query) {
                $query->where('status', 'pending');
            },
            'applications as applications_accepted_count' => function ($query) {
                $query->where('status', 'accepted');
            },
            'applications as applications_rejected_count' => function ($query) {
                $query->where('status', 'rejected');
            },
        ]);
    }

    public function destroy(Announcement $announcement)
    {
        \Illuminate\Support\Facades\Gate::authorize('delete', $announcement);
        $announcement->delete();
        return response()->noContent();
    }

    public function close(Request $request, Announcement $announcement)
    {
        \Illuminate\Support\Facades\Gate::authorize('update', $announcement);

        $announcement->update(['status' => ProjectStatus::CLOSED->value]);

        return response()->json($announcement->load(['category', 'platforms', 'deliverables', 'influencerTier'])->loadCount([
            'applications',
            'applications as applications_pending_count' => function ($query) {
                $query->where('status', 'pending');
            },
            'applications as applications_accepted_count' => function ($query) {
                $query->where('status', 'accepted');
            },
            'applications as applications_rejected_count' => function ($query) {
                $query->where('status', 'rejected');
            },
        ]));
    }
}
