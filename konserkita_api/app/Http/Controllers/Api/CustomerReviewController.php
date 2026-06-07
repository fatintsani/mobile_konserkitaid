<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use App\Models\Review;
use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CustomerReviewController extends BaseController
{
    public function store(Request $request, $eventId)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $user = Auth::user();

        // 1. Check if event exists and is completed
        $event = Event::find($eventId);
        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        // We assume an event is completed if its status is 'completed'
        // OR if the date/time is past. For simplicity, let's enforce status 'completed'
        // But since users might want to review right after it ends, let's check date too.
        $eventDateTime = \Carbon\Carbon::parse($event->date . ' ' . $event->time);
        if ($event->status !== 'completed' && $eventDateTime->isFuture()) {
            return $this->sendError('You can only review an event after it has finished.', [], 400);
        }

        // 2. Check if user has a valid ticket
        $hasBought = Ticket::where('user_id', $user->id)
            ->whereHas('ticketType', function ($q) use ($eventId) {
                $q->where('event_id', $eventId);
            })
            ->where('is_cancelled', false)
            ->exists();

        if (!$hasBought) {
            return $this->sendError('You can only review an event if you have purchased a ticket.', [], 403);
        }

        // 3. Check if already reviewed
        $existingReview = Review::where('user_id', $user->id)
            ->where('event_id', $eventId)
            ->first();

        if ($existingReview) {
            return $this->sendError('You have already reviewed this event.', [], 400);
        }

        // Create review (default pending as per standard moderation practice, or approved if preferred)
        // I'll set default to pending as specified in migration, so Admin can moderate.
        $review = Review::create([
            'user_id' => $user->id,
            'event_id' => $eventId,
            'rating' => $request->rating,
            'comment' => $request->comment,
            'status' => 'pending', // Requires admin approval
        ]);

        \App\Models\Notification::create([
            'user_id' => $user->id,
            'title' => 'Review Submitted',
            'message' => 'Your review for ' . $event->title . ' has been submitted and is awaiting moderation.',
            'type' => 'review'
        ]);

        return $this->sendResponse($review, 'Review submitted successfully and is waiting for moderation.', 201);
    }

    public function myReviews()
    {
        $reviews = Review::with('event:id,title,banner_image')
            ->where('user_id', Auth::id())
            ->latest()
            ->paginate(10);

        return $this->sendResponse($reviews, 'Your reviews retrieved successfully.');
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'rating' => 'sometimes|required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review = Review::where('user_id', Auth::id())->find($id);

        if (!$review) {
            return $this->sendError('Review not found.', [], 404);
        }

        // Optional: If a user updates a review, it goes back to pending?
        // Yes, to prevent abuse.
        $review->update([
            'rating' => $request->rating ?? $review->rating,
            'comment' => $request->has('comment') ? $request->comment : $review->comment,
            'status' => 'pending',
            'admin_note' => null,
        ]);

        return $this->sendResponse($review, 'Review updated successfully and is waiting for moderation.');
    }

    public function destroy($id)
    {
        $review = Review::where('user_id', Auth::id())->find($id);

        if (!$review) {
            return $this->sendError('Review not found.', [], 404);
        }

        $review->delete();

        return $this->sendResponse([], 'Review deleted successfully.');
    }
}
