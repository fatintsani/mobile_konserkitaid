<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\EventRecommendation;
use App\Models\UserEventInteraction;
use App\Models\UserPreference;
use Illuminate\Http\Request;

class AdminRecommendationController extends BaseController
{
    public function analytics(Request $request)
    {
        $totalRecommendations = EventRecommendation::count();
        $totalInteractions = UserEventInteraction::count();
        
        $topCategories = UserPreference::get()->pluck('preferred_categories')->flatten()->countBy()->sortDesc()->take(5);
        $topLocations = UserPreference::get()->pluck('preferred_locations')->flatten()->countBy()->sortDesc()->take(5);

        $interactionStats = UserEventInteraction::selectRaw('interaction_type, count(*) as count')
            ->groupBy('interaction_type')
            ->pluck('count', 'interaction_type');

        return $this->sendResponse([
            'total_recommendations' => $totalRecommendations,
            'total_interactions' => $totalInteractions,
            'top_categories' => $topCategories,
            'top_locations' => $topLocations,
            'interaction_stats' => $interactionStats
        ], 'Analytics retrieved successfully');
    }
}
