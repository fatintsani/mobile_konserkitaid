<?php

namespace App\Http\Controllers\Api;

use App\Models\EventRecommendation;
use App\Models\UserEventInteraction;
use App\Models\UserPreference;
use Illuminate\Http\Request;

class RecommendationController extends BaseController
{
    public function getRecommendations(Request $request)
    {
        $recommendations = EventRecommendation::where('user_id', $request->user()->id)
            ->with(['event', 'event.organizer', 'event.category'])
            ->orderBy('score', 'desc')
            ->take(10)
            ->get();

        // format to just return the events with their reason
        $events = $recommendations->map(function ($rec) {
            $event = $rec->event;
            $event->recommendation_reason = $rec->reason;
            return $event;
        });

        return $this->sendResponse($events, 'Recommendations retrieved successfully');
    }

    public function recordInteraction(Request $request)
    {
        $request->validate([
            'event_id' => 'required|exists:events,id',
            'interaction_type' => 'required|in:view,wishlist,checkout,purchase,review'
        ]);

        $weights = [
            'view' => 1,
            'wishlist' => 3,
            'review' => 4,
            'checkout' => 5,
            'purchase' => 10,
        ];

        UserEventInteraction::create([
            'user_id' => $request->user()->id,
            'event_id' => $request->event_id,
            'interaction_type' => $request->interaction_type,
            'weight' => $weights[$request->interaction_type]
        ]);

        return $this->sendResponse([], 'Interaction recorded');
    }

    public function getPreferences(Request $request)
    {
        $prefs = UserPreference::firstOrCreate(['user_id' => $request->user()->id]);
        return $this->sendResponse($prefs, 'Preferences retrieved');
    }

    public function updatePreferences(Request $request)
    {
        $prefs = UserPreference::firstOrCreate(['user_id' => $request->user()->id]);

        if ($request->has('preferred_categories')) {
            $prefs->preferred_categories = $request->preferred_categories;
        }
        if ($request->has('preferred_locations')) {
            $prefs->preferred_locations = $request->preferred_locations;
        }
        if ($request->has('min_price')) {
            $prefs->min_price = $request->min_price;
        }
        if ($request->has('max_price')) {
            $prefs->max_price = $request->max_price;
        }

        $prefs->save();

        return $this->sendResponse($prefs, 'Preferences updated');
    }
}
