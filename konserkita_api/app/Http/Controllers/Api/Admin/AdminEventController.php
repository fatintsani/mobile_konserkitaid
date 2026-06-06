<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Event;
use Illuminate\Http\Request;

class AdminEventController extends BaseController
{
    public function index(Request $request)
    {
        $status = $request->query('status');

        $query = Event::with('organizer.user');

        if ($status) {
            $query->where('status', $status);
        }

        // Use pagination with 10 items per page
        $events = $query->orderBy('created_at', 'desc')->paginate(10);

        return $this->sendResponse($events, 'Events retrieved successfully.');
    }

    public function show($id)
    {
        $event = Event::with(['organizer.user', 'category', 'ticketTypes'])->find($id);

        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        return $this->sendResponse($event, 'Event details retrieved successfully.');
    }

    public function approve($id)
    {
        $event = Event::find($id);

        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        $event->status = 'published';
        $event->save();

        return $this->sendResponse($event, 'Event approved and published.');
    }

    public function reject($id)
    {
        $event = Event::find($id);

        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        $event->status = 'rejected';
        $event->save();

        return $this->sendResponse($event, 'Event rejected.');
    }

    public function destroy($id)
    {
        $event = Event::find($id);

        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        // Check if there are tickets sold (already implemented in OrganizerController, could duplicate here or simplify)
        $hasTickets = \App\Models\Ticket::whereHas('ticketType', function($q) use ($event) {
            $q->where('event_id', $event->id);
        })->exists();

        if ($hasTickets) {
            return $this->sendError('Cannot delete event with sold tickets.', [], 400);
        }

        $event->delete();

        return $this->sendResponse([], 'Event deleted successfully.');
    }
}
