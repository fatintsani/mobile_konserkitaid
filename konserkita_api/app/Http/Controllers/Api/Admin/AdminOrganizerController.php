<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Organizer;
use Illuminate\Http\Request;

class AdminOrganizerController extends BaseController
{
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

        $organizer->verification_badge = true;
        $organizer->status = 'verified';
        $organizer->save();

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

        $organizer->verification_badge = false;
        $organizer->status = 'rejected';
        $organizer->save();

        return $this->sendResponse($organizer, 'Organizer rejected.');
    }

    public function suspend($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $organizer->verification_badge = false;
        $organizer->status = 'suspended';
        $organizer->save();

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
        
        $review->status = 'approved';
        $review->save();

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
        
        $review->status = 'rejected';
        $review->save();

        return $this->sendResponse($review, 'Review rejected.');
    }
}
