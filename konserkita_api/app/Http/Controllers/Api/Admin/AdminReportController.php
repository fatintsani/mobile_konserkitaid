<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Event;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminReportController extends BaseController
{
    public function sales(Request $request)
    {
        $totalRevenue = Transaction::where('payment_status', 'success')->sum('total_amount');
        
        $totalGrossRevenue = DB::table('transactions')
            ->join('transaction_items', 'transactions.id', '=', 'transaction_items.transaction_id')
            ->where('transactions.payment_status', 'success')
            ->sum('transaction_items.subtotal');

        $platformFeePercentage = config('platform.platform_fee_percentage', 10);
        $totalPlatformFee = $totalGrossRevenue * ($platformFeePercentage / 100);
        $totalOrganizerNetRevenue = $totalGrossRevenue - $totalPlatformFee;

        $totalPaidOut = \App\Models\OrganizerPayout::where('status', 'paid')->sum('amount');
        $totalPendingPayout = \App\Models\OrganizerPayout::whereIn('status', ['pending', 'approved'])->sum('amount');
        
        $revenuePerEvent = DB::table('transactions')
            ->join('transaction_items', 'transactions.id', '=', 'transaction_items.transaction_id')
            ->join('ticket_types', 'transaction_items.ticket_type_id', '=', 'ticket_types.id')
            ->join('events', 'ticket_types.event_id', '=', 'events.id')
            ->where('transactions.payment_status', 'success')
            ->select('events.id', 'events.title', DB::raw('SUM(transaction_items.quantity * transaction_items.price) as revenue'), DB::raw('SUM(transaction_items.quantity) as tickets_sold'))
            ->groupBy('events.id', 'events.title')
            ->orderBy('revenue', 'desc')
            ->get();

        return $this->sendResponse([
            'total_revenue' => $totalRevenue,
            'total_gross_revenue' => $totalGrossRevenue,
            'total_platform_fee' => $totalPlatformFee,
            'total_organizer_net_revenue' => $totalOrganizerNetRevenue,
            'total_paid_out' => $totalPaidOut,
            'total_pending_payout' => $totalPendingPayout,
            'revenue_per_event' => $revenuePerEvent,
        ], 'Sales reports retrieved successfully.');
    }
}
