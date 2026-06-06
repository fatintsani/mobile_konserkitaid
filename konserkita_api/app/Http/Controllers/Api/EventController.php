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

        if ($request->has('category_id') && $request->category_id != '') {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search') && $request->search != '') {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        if ($request->has('city') && $request->city != '') {
            $query->where('location', 'like', '%' . $request->city . '%');
        }

        if ($request->has('start_date') && $request->start_date != '') {
            $query->where('date', '>=', $request->start_date);
        }

        if ($request->has('end_date') && $request->end_date != '') {
            $query->where('date', '<=', $request->end_date);
        }

        if ($request->has('min_price') && $request->min_price != '') {
            $query->whereHas('ticketTypes', function ($q) use ($request) {
                $q->where('price', '>=', $request->min_price);
            });
        }

        if ($request->has('max_price') && $request->max_price != '') {
            $query->whereHas('ticketTypes', function ($q) use ($request) {
                $q->where('price', '<=', $request->max_price);
            });
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
