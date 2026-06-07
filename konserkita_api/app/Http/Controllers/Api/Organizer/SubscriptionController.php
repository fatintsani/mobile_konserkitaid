<?php

namespace App\Http\Controllers\Api\Organizer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\SubscriptionPlan;
use App\Models\OrganizerSubscription;
use App\Models\SubscriptionPayment;

class SubscriptionController extends Controller
{
    public function getSubscription(Request $request)
    {
        $user = $request->user();
        if (!$user->organizer) {
            return response()->json(['success' => false, 'message' => 'Organizer profile not found'], 404);
        }

        $subscription = OrganizerSubscription::with('plan')
            ->where('organizer_id', $user->organizer->id)
            ->latest('id')
            ->first();

        $limits = $user->organizer->limits;

        return response()->json([
            'success' => true,
            'data' => [
                'subscription' => $subscription,
                'limits' => $limits
            ]
        ]);
    }

    public function upgrade(Request $request)
    {
        $request->validate([
            'plan_id' => 'required|exists:subscription_plans,id',
        ]);

        $user = $request->user();
        $plan = SubscriptionPlan::findOrFail($request->plan_id);

        if ($plan->price == 0) {
            return response()->json(['success' => false, 'message' => 'Cannot upgrade to a free plan directly through payment.'], 400);
        }

        $subscription = OrganizerSubscription::create([
            'organizer_id' => $user->organizer->id,
            'subscription_plan_id' => $plan->id,
            'status' => 'past_due', // Will be active after payment
        ]);

        $invoiceNumber = 'SUB-' . time() . '-' . $subscription->id;

        $payment = SubscriptionPayment::create([
            'organizer_subscription_id' => $subscription->id,
            'invoice_number' => $invoiceNumber,
            'amount' => $plan->price,
            'payment_status' => 'pending',
        ]);

        \Midtrans\Config::$serverKey = config('midtrans.server_key');
        \Midtrans\Config::$isProduction = config('midtrans.is_production');
        \Midtrans\Config::$isSanitized = true;
        \Midtrans\Config::$is3ds = true;

        $params = [
            'transaction_details' => [
                'order_id' => $invoiceNumber,
                'gross_amount' => $plan->price,
            ],
            'customer_details' => [
                'first_name' => $user->name,
                'email' => $user->email,
            ],
        ];

        try {
            $snapToken = \Midtrans\Snap::getSnapToken($params);
            $payment->update(['snap_token' => $snapToken]);

            return response()->json([
                'success' => true,
                'data' => [
                    'snap_token' => $snapToken,
                    'payment' => $payment
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function payments(Request $request)
    {
        $user = $request->user();
        
        $payments = SubscriptionPayment::whereHas('subscription', function($query) use ($user) {
            $query->where('organizer_id', $user->organizer->id);
        })->latest('id')->get();

        return response()->json([
            'success' => true,
            'data' => $payments
        ]);
    }

    public function cancel(Request $request)
    {
        $user = $request->user();
        $subscription = OrganizerSubscription::where('organizer_id', $user->organizer->id)
            ->whereIn('status', ['active', 'trialing'])
            ->latest('id')
            ->first();

        if (!$subscription) {
            return response()->json(['success' => false, 'message' => 'No active subscription found to cancel'], 404);
        }

        $subscription->update([
            'status' => 'cancelled',
            'cancelled_at' => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Subscription cancelled successfully']);
    }
}
