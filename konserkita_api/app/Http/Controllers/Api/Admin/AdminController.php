<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Event;
use App\Models\Organizer;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends BaseController
{
    public function dashboard(Request $request)
    {
        $totalUsers = User::count();
        $totalOrganizers = Organizer::count();
        $totalEvents = Event::count();
        $pendingEvents = Event::where('status', 'pending')->count();
        
        $totalTransactions = Transaction::where('payment_status', 'success')->count();
        $totalRevenue = Transaction::where('payment_status', 'success')->sum('total_amount');

        $recentTransactions = Transaction::with('user:id,name,email')
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        return $this->sendResponse([
            'total_users' => $totalUsers,
            'total_organizers' => $totalOrganizers,
            'total_events' => $totalEvents,
            'pending_events' => $pendingEvents,
            'total_transactions' => $totalTransactions,
            'total_revenue' => $totalRevenue,
            'recent_transactions' => $recentTransactions,
        ], 'Admin dashboard retrieved successfully.');
    }
}
