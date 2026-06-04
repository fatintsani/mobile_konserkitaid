<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use App\Models\Organizer;
use App\Models\Ticket;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

        $totalTicketsSold = Ticket::whereHas('ticketType', function ($q) use ($event->id) {
            $q->where('event_id', $event->id);
        })->count();

        $totalRevenue = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($event->id) {
                $q->where('event_id', $event->id);
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

        $totalTransactions = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($event->id) {
                $q->where('event_id', $event->id);
            })->count();

        $totalTicketsSold = Ticket::whereHas('ticketType', function ($q) use ($event->id) {
            $q->where('event_id', $event->id);
        })->count();

        $totalRevenue = Transaction::where('payment_status', 'success')
            ->whereHas('items.ticketType', function ($q) use ($event->id) {
                $q->where('event_id', $event->id);
            })->sum('total_amount');

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
            'total_revenue' => $totalRevenue,
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

        $tickets = Ticket::with(['user', 'ticketType'])
            ->whereHas('ticketType', function ($q) use ($event->id) {
                $q->where('event_id', $event->id);
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
}
