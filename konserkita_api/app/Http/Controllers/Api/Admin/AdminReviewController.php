<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Review;
use Illuminate\Http\Request;
use App\Services\AdminAuditService;

class AdminReviewController extends BaseController
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
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

        $oldValues = $review->toArray();
        $review->update([
            'status' => 'approved',
            'admin_note' => null,
        ]);

        $this->auditService->log(
            auth()->user(),
            'review_approved',
            'reviews',
            $review,
            $oldValues,
            $review->toArray(),
            "Approved review #{$review->id}"
        );

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

        $oldValues = $review->toArray();
        $review->update([
            'status' => 'rejected',
            'admin_note' => $request->admin_note,
        ]);

        $this->auditService->log(
            auth()->user(),
            'review_rejected',
            'reviews',
            $review,
            $oldValues,
            $review->toArray(),
            "Rejected review #{$review->id}"
        );

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

        $oldValues = $review->toArray();
        $review->delete();

        $this->auditService->log(
            auth()->user(),
            'review_deleted',
            'reviews',
            $review,
            $oldValues,
            null,
            "Deleted review #{$review->id}"
        );

        return $this->sendResponse([], 'Review deleted successfully.');
    }
}
