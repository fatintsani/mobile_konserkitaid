<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use App\Models\Review;
use Illuminate\Http\Request;

class EventReviewController extends BaseController
{
    public function index($eventId)
    {
        $reviews = Review::with('user:id,name,avatar')
            ->where('event_id', $eventId)
            ->where('status', 'approved')
            ->latest()
            ->paginate(10);

        return $this->sendResponse($reviews, 'Event reviews retrieved successfully.');
    }

    public function ratingSummary($eventId)
    {
        $summary = Review::where('event_id', $eventId)
            ->where('status', 'approved')
            ->selectRaw('ROUND(AVG(rating), 1) as average_rating, COUNT(*) as total_reviews')
            ->first();

        return $this->sendResponse([
            'average_rating' => (float) $summary->average_rating,
            'total_reviews' => $summary->total_reviews,
        ], 'Rating summary retrieved successfully.');
    }
}
