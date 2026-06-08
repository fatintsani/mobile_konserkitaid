<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Organizer;
use Illuminate\Http\Request;
use App\Services\AdminAuditService;

class AdminOrganizerController extends BaseController
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
    public function index(Request $request)
    {
        $organizers = Organizer::with('user')->withCount(['events', 'followers', 'reviews'])->orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($organizers, 'Organizers retrieved successfully.');
    }

    public function show($id)
    {
        $organizer = Organizer::with('user')->withCount(['events', 'followers', 'reviews'])->find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        return $this->sendResponse($organizer, 'Organizer details retrieved successfully.');
    }

    public function verify($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $oldValues = $organizer->toArray();
        $organizer->verification_badge = true;
        $organizer->status = 'verified';
        $organizer->save();

        $this->auditService->log(
            auth()->user(),
            'organizer_verified',
            'organizers',
            $organizer,
            $oldValues,
            $organizer->toArray(),
            "Verified organizer: {$organizer->company_name}"
        );

        \App\Models\Notification::create([
            'user_id' => $organizer->user_id,
            'title' => 'Organizer Verified',
            'message' => 'Congratulations! Your organizer account has been verified.',
            'type' => 'organizer_verified',
        ]);

        return $this->sendResponse($organizer, 'Organizer verified successfully.');
    }

    public function reject($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $oldValues = $organizer->toArray();
        $organizer->verification_badge = false;
        $organizer->status = 'rejected';
        $organizer->save();

        $this->auditService->log(
            auth()->user(),
            'organizer_rejected',
            'organizers',
            $organizer,
            $oldValues,
            $organizer->toArray(),
            "Rejected organizer: {$organizer->company_name}"
        );

        return $this->sendResponse($organizer, 'Organizer rejected.');
    }

    public function suspend($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $oldValues = $organizer->toArray();
        $organizer->verification_badge = false;
        $organizer->status = 'suspended';
        $organizer->save();

        $this->auditService->log(
            auth()->user(),
            'organizer_suspended',
            'organizers',
            $organizer,
            $oldValues,
            $organizer->toArray(),
            "Suspended organizer: {$organizer->company_name}"
        );

        \App\Models\Notification::create([
            'user_id' => $organizer->user_id,
            'title' => 'Organizer Suspended',
            'message' => 'Your organizer account has been suspended due to violations.',
            'type' => 'organizer_suspended',
        ]);

        return $this->sendResponse($organizer, 'Organizer suspended.');
    }

    public function reviews(Request $request)
    {
        $reviews = \App\Models\OrganizerReview::with(['user', 'organizer'])->orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($reviews, 'Organizer reviews retrieved successfully.');
    }

    public function approveReview($id)
    {
        $review = \App\Models\OrganizerReview::find($id);
        if (!$review) return $this->sendError('Review not found.', [], 404);
        
        $oldValues = $review->toArray();
        $review->status = 'approved';
        $review->save();

        $this->auditService->log(
            auth()->user(),
            'organizer_review_approved',
            'organizer_reviews',
            $review,
            $oldValues,
            $review->toArray(),
            "Approved review ID: {$review->id}"
        );

        // Update organizer total_reviews and rating_average
        $organizer = $review->organizer;
        $organizer->total_reviews = $organizer->reviews()->where('status', 'approved')->count();
        $organizer->rating_average = $organizer->reviews()->where('status', 'approved')->avg('rating') ?? 0;
        $organizer->save();

        \App\Models\Notification::create([
            'user_id' => $review->user_id,
            'title' => 'Review Approved',
            'message' => 'Your review for ' . $organizer->company_name . ' has been approved and published.',
            'type' => 'review_approved',
        ]);

        return $this->sendResponse($review, 'Review approved.');
    }

    public function rejectReview($id)
    {
        $review = \App\Models\OrganizerReview::find($id);
        if (!$review) return $this->sendError('Review not found.', [], 404);
        
        $oldValues = $review->toArray();
        $review->status = 'rejected';
        $review->save();

        $this->auditService->log(
            auth()->user(),
            'organizer_review_rejected',
            'organizer_reviews',
            $review,
            $oldValues,
            $review->toArray(),
            "Rejected review ID: {$review->id}"
        );

        return $this->sendResponse($review, 'Review rejected.');
    }
}
