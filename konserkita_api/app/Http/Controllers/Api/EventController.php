<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use Illuminate\Http\Request;

class EventController extends BaseController
{
    public function index(Request $request)
    {
        $query = Event::with(['organizer', 'category', 'ticketTypes'])
            ->where('status', 'published');

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        $events = $query->latest()->paginate(10);

        return $this->sendResponse($events, 'Events retrieved successfully.');
    }

    public function show($id)
    {
        $event = Event::with(['organizer', 'category', 'ticketTypes'])->find($id);

        if (is_null($event)) {
            return $this->sendError('Event not found.');
        }

        return $this->sendResponse($event, 'Event retrieved successfully.');
    }
}
