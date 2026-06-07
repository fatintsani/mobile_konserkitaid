<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use App\Models\Organizer;
use App\Models\Ticket;
use App\Models\Transaction;
use App\Models\EventCategory;
use App\Models\TicketType;
use App\Http\Requests\StoreEventRequest;
use App\Http\Requests\UpdateEventRequest;
use App\Http\Requests\StoreTicketTypeRequest;
use App\Http\Requests\UpdateTicketTypeRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class OrganizerController extends BaseController
{
    private function getOrganizerId(Request $request)
    {
        $user = $request->user();
        if (in_array($user->role, ['admin', 'super_admin'])) {
            // Admins can see everything, or maybe they also have an organizer profile?
            // For simplicity, if they don't have an organizer profile, return null or all
            $organizer = Organizer::where('user_id', $user->id)->first();
            return $organizer ? $organizer->id : null;
        }
        
        $organizer = Organizer::where('user_id', $user->id)->first();
        if (!$organizer) {
            abort(403, 'Organizer profile not found.');
        }
        return $organizer->id;
    }

    public function dashboard(Request $request)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventsQuery = Event::query();
        if ($organizerId) {
            $eventsQuery->where('organizer_id', $organizerId);
        }

        $totalEvents = $eventsQuery->count();
        $activeEventsQuery = clone $eventsQuery;
        $activeEvents = $activeEventsQuery->where('status', 'published')->count();
        $upcomingEventsQuery = clone $eventsQuery;
        $upcomingEvents = $upcomingEventsQuery->where('status', 'published')->where('date', '>=', date('Y-m-d'))->count();

        $eventIds = $eventsQuery->pluck('id');

        $totalTicketsSold = Ticket::whereHas('ticketType', function ($q) use ($eventIds) {
            $q->whereIn('event_id', $eventIds);
        })->count();

        $totalRevenue = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($eventIds) {
                $q->whereIn('event_id', $eventIds);
            })->sum('total_amount');

        $checkedInCount = Ticket::where('is_used', true)
            ->whereHas('ticketType', function ($q) use ($eventIds) {
                $q->whereIn('event_id', $eventIds);
            })->count();

        return $this->sendResponse([
            'total_events' => $totalEvents,
            'total_tickets_sold' => $totalTicketsSold,
            'total_revenue' => $totalRevenue,
            'upcoming_events' => $upcomingEvents,
            'checked_in_count' => $checkedInCount,
            'active_events' => $activeEvents,
        ], 'Dashboard data retrieved successfully.');
    }

    public function events(Request $request)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventsQuery = Event::with('category');
        if ($organizerId) {
            $eventsQuery->where('organizer_id', $organizerId);
        }

        $events = $eventsQuery->latest()->get();

        return $this->sendResponse($events, 'Events retrieved successfully.');
    }

    public function eventDetail(Request $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::with(['category', 'ticketTypes']);
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();

        if (!$event) {
            return $this->sendError('Event not found.');
        }

        $eventId = $event->id;

        $totalTicketsSold = Ticket::whereHas('ticketType', function ($q) use ($eventId) {
            $q->where('event_id', $eventId);
        })->count();

        $totalRevenue = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($eventId) {
                $q->where('event_id', $eventId);
            })->sum('total_amount');

        $eventData = $event->toArray();
        $eventData['total_tickets_sold'] = $totalTicketsSold;
        $eventData['total_revenue'] = $totalRevenue;

        return $this->sendResponse($eventData, 'Event detail retrieved successfully.');
    }

    public function sales(Request $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::with('ticketTypes');
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();

        if (!$event) {
            return $this->sendError('Event not found.');
        }

        $eventId = $event->id;

        $totalTransactions = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($eventId) {
                $q->where('event_id', $eventId);
            })->count();

        $totalTicketsSold = Ticket::whereHas('ticketType', function ($q) use ($eventId) {
            $q->where('event_id', $eventId);
        })->count();

        // Calculate gross revenue properly based on items
        $grossRevenue = \App\Models\TransactionItem::whereHas('transaction', function($q) {
            $q->where('payment_status', 'success');
        })->whereHas('ticketType', function($q) use ($eventId) {
            $q->where('event_id', $eventId);
        })->sum('subtotal');

        $organizer = \App\Models\Organizer::find($event->organizer_id);
        $subscription = $organizer ? $organizer->subscription()->with('plan')->first() : null;
        $platformFeePercentage = $subscription ? $subscription->plan->platform_fee_percentage : config('platform.platform_fee_percentage', 10);
        $platformFee = $grossRevenue * ($platformFeePercentage / 100);
        $netRevenue = $grossRevenue - $platformFee;

        // Payout status for this event
        $paidOut = \App\Models\OrganizerPayout::where('event_id', $eventId)->where('status', 'paid')->sum('amount');
        $pendingPayout = \App\Models\OrganizerPayout::where('event_id', $eventId)->whereIn('status', ['pending', 'approved'])->sum('amount');

        $ticketsByType = DB::table('tickets')
            ->join('ticket_types', 'tickets.ticket_type_id', '=', 'ticket_types.id')
            ->where('ticket_types.event_id', $event->id)
            ->select('ticket_types.name', DB::raw('count(*) as total_sold'), DB::raw('sum(ticket_types.price) as revenue'))
            ->groupBy('ticket_types.id', 'ticket_types.name')
            ->get();

        return $this->sendResponse([
            'event_id' => $event->id,
            'event_title' => $event->title,
            'total_transactions' => $totalTransactions,
            'total_tickets_sold' => $totalTicketsSold,
            'gross_revenue' => (float) $grossRevenue,
            'platform_fee' => (float) $platformFee,
            'net_revenue' => (float) $netRevenue,
            'paid_out' => (float) $paidOut,
            'pending_payout' => (float) $pendingPayout,
            'tickets_by_type' => $ticketsByType,
        ], 'Sales data retrieved successfully.');
    }

    public function attendees(Request $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::query();
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();

        if (!$event) {
            return $this->sendError('Event not found.');
        }

        $eventId = $event->id;

        $tickets = Ticket::with(['user', 'ticketType'])
            ->whereHas('ticketType', function ($q) use ($eventId) {
                $q->where('event_id', $eventId);
            })
            ->latest()
            ->get();

        $attendees = $tickets->map(function ($ticket) {
            return [
                'ticket_code' => $ticket->ticket_code,
                'customer_name' => $ticket->user->name ?? 'Unknown',
                'customer_email' => $ticket->user->email ?? 'Unknown',
                'ticket_type' => $ticket->ticketType->name ?? 'Unknown',
                'status' => $ticket->is_used ? 'used' : 'active',
                'checked_in_at' => $ticket->is_used ? $ticket->updated_at : null,
            ];
        });

        return $this->sendResponse($attendees, 'Attendees retrieved successfully.');
    }

    public function storeEvent(StoreEventRequest $request)
    {
        $organizerId = $this->getOrganizerId($request);
        if (!$organizerId) {
            return $this->sendError('You must have an organizer profile to create events.', [], 403);
        }

        $organizer = \App\Models\Organizer::find($organizerId);

        // SaaS Limit Check
        $subscription = $organizer->subscription()->with('plan')->first();
        if (!$subscription || !in_array($subscription->status, ['active', 'trialing'])) {
            return $this->sendError('You must have an active subscription to create events.', [], 403);
        }

        $limits = $organizer->limits()->firstOrCreate(['organizer_id' => $organizerId]);
        if ($limits->current_month_events >= $subscription->plan->max_events) {
            return $this->sendError('You have reached your maximum event limit for your current subscription plan.', [], 403);
        }

        $data = $request->validated();
        $data['organizer_id'] = $organizerId;
        $data['slug'] = Str::slug($data['title']) . '-' . time();

        if ($request->hasFile('banner_image')) {
            $path = $request->file('banner_image')->store('banners', 'public');
            $data['banner_image'] = Storage::url($path);
        }

        // Default status is pending for organizer
        if (!isset($data['status'])) {
            $data['status'] = 'pending';
        }

        // Admin/Super Admin can set status directly
        $user = $request->user();
        if (in_array($user->role, ['admin', 'super_admin']) && $request->has('status')) {
            $data['status'] = $request->status;
        } else {
            $data['status'] = 'pending';
        }

        $event = Event::create($data);

        // Increment usage
        if ($limits) {
            $limits->increment('current_month_events');
        }

        return $this->sendResponse($event, 'Event created successfully.');
    }

    public function updateEvent(UpdateEventRequest $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::query();
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();
        if (!$event) {
            return $this->sendError('Event not found or unauthorized.');
        }

        $data = $request->validated();
        
        if (isset($data['title'])) {
            $data['slug'] = Str::slug($data['title']) . '-' . time();
        }

        if ($request->hasFile('banner_image')) {
            $path = $request->file('banner_image')->store('banners', 'public');
            $data['banner_image'] = Storage::url($path);
        }

        $user = $request->user();
        if (in_array($user->role, ['admin', 'super_admin']) && $request->has('status')) {
            $data['status'] = $request->status;
        } else {
            unset($data['status']); // organizer cannot update status directly through this endpoint
        }

        $event->update($data);

        return $this->sendResponse($event, 'Event updated successfully.');
    }

    public function destroyEvent(Request $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::query();
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();
        if (!$event) {
            return $this->sendError('Event not found or unauthorized.');
        }

        // check if event has tickets sold
        $ticketsSold = Ticket::whereHas('ticketType', function($q) use ($event) {
            $q->where('event_id', $event->id);
        })->exists();

        if ($ticketsSold) {
            return $this->sendError('Cannot delete event because tickets have already been sold.', [], 400);
        }

        $event->delete();

        return $this->sendResponse([], 'Event deleted successfully.');
    }

    public function storeTicketType(StoreTicketTypeRequest $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $eventQuery = Event::query();
        if ($organizerId) {
            $eventQuery->where('organizer_id', $organizerId);
        }

        $event = $eventQuery->where('id', $id)->first();
        if (!$event) {
            return $this->sendError('Event not found or unauthorized.');
        }

        $data = $request->validated();
        $data['event_id'] = $event->id;
        
        $quota = $data['quota'] ?? 0;
        
        if ($organizerId) {
            $organizer = \App\Models\Organizer::find($organizerId);
            $subscription = $organizer->subscription()->with('plan')->first();
            if ($subscription && $quota > $subscription->plan->max_tickets_per_event) {
                return $this->sendError('Ticket quota exceeds your subscription plan limit (' . $subscription->plan->max_tickets_per_event . ').', [], 403);
            }
        }

        if (isset($data['quota'])) {
            $data['stock'] = $data['quota'];
            unset($data['quota']);
        }
        unset($data['status']);

        $ticketType = TicketType::create($data);

        return $this->sendResponse($ticketType, 'Ticket type created successfully.');
    }

    public function updateTicketType(UpdateTicketTypeRequest $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $ticketType = TicketType::where('id', $id)->first();
        if (!$ticketType) {
            return $this->sendError('Ticket type not found.');
        }

        $event = Event::where('id', $ticketType->event_id)->first();
        if ($organizerId && $event->organizer_id != $organizerId) {
            return $this->sendError('Unauthorized.');
        }

        $data = $request->validated();
        if (isset($data['quota'])) {
            $data['stock'] = $data['quota'];
            unset($data['quota']);
        }
        unset($data['status']);

        $ticketType->update($data);

        return $this->sendResponse($ticketType, 'Ticket type updated successfully.');
    }

    public function destroyTicketType(Request $request, $id)
    {
        $organizerId = $this->getOrganizerId($request);
        
        $ticketType = TicketType::where('id', $id)->first();
        if (!$ticketType) {
            return $this->sendError('Ticket type not found.');
        }

        $event = Event::where('id', $ticketType->event_id)->first();
        if ($organizerId && $event->organizer_id != $organizerId) {
            return $this->sendError('Unauthorized.');
        }

        $ticketsSold = Ticket::where('ticket_type_id', $ticketType->id)->exists();
        if ($ticketsSold) {
            return $this->sendError('Cannot delete ticket type because tickets have already been sold.', [], 400);
        }

        $ticketType->delete();

        return $this->sendResponse([], 'Ticket type deleted successfully.');
    }

    public function getCategories(Request $request)
    {
        $categories = EventCategory::all();
        return $this->sendResponse($categories, 'Categories retrieved successfully.');
    }
}
