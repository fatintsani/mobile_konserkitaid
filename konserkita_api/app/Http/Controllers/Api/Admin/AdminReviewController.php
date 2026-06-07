<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Review;
use Illuminate\Http\Request;

class AdminReviewController extends BaseController
{
    public function index(Request $request)
    {
        $query = Review::with(['user', 'event']);

        if ($request->has('status') && $request->status != '') {
            $query->where('status', $request->status);
        }

        if ($request->has('rating') && $request->rating != '') {
            $query->where('rating', $request->rating);
        }

        $reviews = $query->latest()->paginate(10);

        return $this->sendResponse($reviews, 'Reviews retrieved successfully.');
    }

    public function approve($id)
    {
        $review = Review::find($id);

        if (!$review) {
            return $this->sendError('Review not found.', [], 404);
        }

        $review->update([
            'status' => 'approved',
            'admin_note' => null,
        ]);

        \App\Models\Notification::create([
            'user_id' => $review->user_id,
            'title' => 'Review Approved',
            'message' => 'Your review for ' . $review->event->title . ' has been approved and is now live.',
            'type' => 'review'
        ]);

        return $this->sendResponse($review, 'Review approved successfully.');
    }

    public function reject(Request $request, $id)
    {
        $request->validate([
            'admin_note' => 'required|string|max:500',
        ]);

        $review = Review::find($id);

        if (!$review) {
            return $this->sendError('Review not found.', [], 404);
        }

        $review->update([
            'status' => 'rejected',
            'admin_note' => $request->admin_note,
        ]);

        \App\Models\Notification::create([
            'user_id' => $review->user_id,
            'title' => 'Review Rejected',
            'message' => 'Your review for ' . $review->event->title . ' has been rejected. Reason: ' . $review->admin_note,
            'type' => 'review'
        ]);

        return $this->sendResponse($review, 'Review rejected successfully.');
    }

    public function destroy($id)
    {
        $review = Review::find($id);

        if (!$review) {
            return $this->sendError('Review not found.', [], 404);
        }

        $review->delete();

        return $this->sendResponse([], 'Review deleted successfully.');
    }
}
