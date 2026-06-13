<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Collaboration;
use App\Models\CollaborationReview;
use App\Services\NotificationService;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CollaborationReviewController extends Controller
{
    public function store(Request $request, Collaboration $collaboration)
    {
        $user = $request->user();

        if (! $this->isParticipant($collaboration, $user->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($collaboration->status !== 'completed') {
            return response()->json([
                'message' => 'La collaboration doit être terminée avant de laisser un avis.',
            ], 422);
        }

        if ($collaboration->reviews()->where('reviewer_id', $user->id)->exists()) {
            return $this->duplicateReviewResponse();
        }

        $validated = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'communication_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'quality_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'reliability_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'professionalism_rating' => ['nullable', 'integer', 'min:1', 'max:5'],
            'would_work_again' => ['nullable', 'boolean'],
            'public_comment' => ['nullable', 'string', 'max:2000'],
            'status' => ['nullable', Rule::in(['published'])],
        ]);

        $reviewedUser = $user->id === $collaboration->brand_id
            ? $collaboration->creator
            : $collaboration->brand;

        try {
            $review = CollaborationReview::create([
                'collaboration_id' => $collaboration->id,
                'reviewer_id' => $user->id,
                'reviewed_user_id' => $reviewedUser->id,
                'reviewer_role' => $user->id === $collaboration->brand_id ? 'brand' : 'creator',
                'rating' => $validated['rating'],
                'communication_rating' => $validated['communication_rating'] ?? null,
                'quality_rating' => $validated['quality_rating'] ?? null,
                'reliability_rating' => $validated['reliability_rating'] ?? null,
                'professionalism_rating' => $validated['professionalism_rating'] ?? null,
                'would_work_again' => $validated['would_work_again'] ?? null,
                'public_comment' => $validated['public_comment'] ?? null,
                'status' => 'published',
            ]);
        } catch (QueryException $exception) {
            if ($this->isDuplicateReviewException($exception)) {
                return $this->duplicateReviewResponse();
            }

            throw $exception;
        }

        $routePrefix = $reviewedUser->isBrand() ? '/brand' : '/creator';

        NotificationService::send(
            $reviewedUser,
            'review_received',
            'Nouvel avis',
            "{$user->display_name} a laissé un avis sur votre collaboration.",
            [
                'route' => $routePrefix.'/collaboration-details/'.$collaboration->id,
                'params' => ['id' => $collaboration->id],
            ]
        );

        return response()->json(
            $review->load([
                'reviewer.brandProfile',
                'reviewer.creatorProfile',
                'reviewedUser.brandProfile',
                'reviewedUser.creatorProfile',
            ]),
            201
        );
    }

    private function isParticipant(Collaboration $collaboration, int $userId): bool
    {
        return $collaboration->brand_id === $userId || $collaboration->creator_id === $userId;
    }

    private function duplicateReviewResponse()
    {
        return response()->json([
            'message' => 'Vous avez déjà laissé un avis pour cette collaboration.',
        ], 422);
    }

    private function isDuplicateReviewException(QueryException $exception): bool
    {
        return in_array((string) $exception->getCode(), ['23000', '23505'], true);
    }
}
