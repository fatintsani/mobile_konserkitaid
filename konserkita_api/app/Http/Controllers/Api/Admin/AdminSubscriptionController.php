<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\SubscriptionPlan;
use App\Models\OrganizerSubscription;
use App\Models\SubscriptionPayment;

class AdminSubscriptionController extends Controller
{
    public function getPlans()
    {
        return response()->json([
            'success' => true,
            'data' => SubscriptionPlan::all()
        ]);
    }

    public function createPlan(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'slug' => 'required|string|unique:subscription_plans',
            'price' => 'required|numeric',
            'billing_cycle' => 'required|in:monthly,yearly',
            'max_events' => 'required|integer',
            'max_tickets_per_event' => 'required|integer',
            'max_admin_users' => 'required|integer',
            'platform_fee_percentage' => 'required|numeric',
            'features' => 'nullable|array',
            'status' => 'required|in:active,inactive'
        ]);

        $plan = SubscriptionPlan::create($validated);

        return response()->json([
            'success' => true,
            'data' => $plan,
            'message' => 'Subscription plan created successfully'
        ]);
    }

    public function updatePlan(Request $request, $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string',
            'slug' => 'required|string|unique:subscription_plans,slug,' . $plan->id,
            'price' => 'required|numeric',
            'billing_cycle' => 'required|in:monthly,yearly',
            'max_events' => 'required|integer',
            'max_tickets_per_event' => 'required|integer',
            'max_admin_users' => 'required|integer',
            'platform_fee_percentage' => 'required|numeric',
            'features' => 'nullable|array',
            'status' => 'required|in:active,inactive'
        ]);

        $plan->update($validated);

        return response()->json([
            'success' => true,
            'data' => $plan,
            'message' => 'Subscription plan updated successfully'
        ]);
    }

    public function deletePlan($id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        
        if ($plan->subscriptions()->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete plan as it has active subscriptions'
            ], 400);
        }

        $plan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Subscription plan deleted successfully'
        ]);
    }

    public function getSubscriptions()
    {
        $subscriptions = OrganizerSubscription::with(['organizer.user', 'plan'])->get();

        return response()->json([
            'success' => true,
            'data' => $subscriptions
        ]);
    }

    public function getSubscription($id)
    {
        $subscription = OrganizerSubscription::with(['organizer.user', 'plan', 'payments'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $subscription
        ]);
    }
}
