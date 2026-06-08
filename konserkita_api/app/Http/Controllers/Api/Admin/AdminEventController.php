<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Event;
use Illuminate\Http\Request;
use App\Services\AdminAuditService;

class AdminEventController extends BaseController
{
    protected $auditService;

    public function __construct(AdminAuditService $auditService)
    {
        $this->auditService = $auditService;
    }
    public function index(Request $request)
    {
        $status = $request->query('status');

        $query = Event::with(['organizer.user', 'seatMap.venue']);

        if ($status) {
            $query->where('status', $status);
        }

        // Use pagination with 10 items per page
        $events = $query->orderBy('created_at', 'desc')->paginate(10);

        return $this->sendResponse($events, 'Events retrieved successfully.');
    }

    public function show($id)
    {
        $event = Event::with(['organizer.user', 'category', 'ticketTypes', 'seatMap.venue'])->find($id);

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

        $oldValues = $event->toArray();
        $event->status = 'published';
        $event->save();

        $this->auditService->log(
            auth()->user(),
            'event_approved',
            'events',
            $event,
            $oldValues,
            $event->toArray(),
            "Approved event: {$event->title}"
        );

        // Increment organizer's total events
        if ($event->organizer) {
            $event->organizer->increment('total_events');
            
            // Notify followers
            $followers = $event->organizer->followers;
            foreach ($followers as $follower) {
                \App\Models\Notification::create([
                    'user_id' => $follower->id,
                    'title' => 'New Event from ' . $event->organizer->public_name,
                    'message' => $event->organizer->public_name . ' has published a new event: ' . $event->title . '! Check it out now.',
                    'type' => 'organizer_new_event',
                ]);
            }
        }

        return $this->sendResponse($event, 'Event approved and published.');
    }

    public function reject($id)
    {
        $event = Event::find($id);

        if (!$event) {
            return $this->sendError('Event not found.', [], 404);
        }

        $oldValues = $event->toArray();
        $event->status = 'rejected';
        $event->save();

        $this->auditService->log(
            auth()->user(),
            'event_rejected',
            'events',
            $event,
            $oldValues,
            $event->toArray(),
            "Rejected event: {$event->title}"
        );

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

        $oldValues = $event->toArray();
        $event->delete();

        $this->auditService->log(
            auth()->user(),
            'event_deleted',
            'events',
            $event,
            $oldValues,
            null,
            "Deleted event: {$event->title}"
        );

        return $this->sendResponse([], 'Event deleted successfully.');
    }
}
