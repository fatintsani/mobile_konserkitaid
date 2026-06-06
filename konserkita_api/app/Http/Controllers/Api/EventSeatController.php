<?php

namespace App\Http\Controllers\Api;

use App\Models\Event;
use App\Models\EventSeatMap;
use App\Models\Seat;
use App\Models\SeatReservation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EventSeatController extends BaseController
{
    public function getSeatMap($eventId)
    {
        $event = Event::find($eventId);
        if (!$event || !$event->is_numbered_seating) {
            return $this->sendError('Event not found or does not support numbered seating.');
        }

        $seatMap = EventSeatMap::where('event_id', $event->id)->with(['venue.sections.seats'])->first();
        if (!$seatMap) {
            return $this->sendError('Seat map not configured for this event.');
        }

        $reservations = SeatReservation::where('event_id', $event->id)
            ->where(function($q) {
                $q->where('status', 'sold')
                  ->orWhere(function($q2) {
                      $q2->where('status', 'held')->where('hold_expires_at', '>', now());
                  });
            })->get()->keyBy('seat_id');

        $venue = $seatMap->venue;
        
        $data = [
            'venue_name' => $venue->name,
            'sections' => $venue->sections->map(function($section) use ($reservations) {
                return [
                    'id' => $section->id,
                    'name' => $section->name,
                    'label' => $section->label,
                    'seats' => $section->seats->map(function($seat) use ($reservations) {
                        $res = $reservations->get($seat->id);
                        $status = 'available';
                        if ($res) {
                            $status = $res->status; // 'held' or 'sold'
                            // If it's held by the current user, maybe return a special status?
                            if ($status === 'held' && request()->user() && $res->user_id === request()->user()->id) {
                                $status = 'selected';
                            }
                        }
                        
                        return [
                            'id' => $seat->id,
                            'row_label' => $seat->row_label,
                            'seat_number' => $seat->seat_number,
                            'seat_code' => $seat->seat_code,
                            'status' => $status,
                        ];
                    })->groupBy('row_label')
                ];
            })
        ];

        return $this->sendResponse($data, 'Seat map retrieved successfully.');
    }

    public function holdSeats(Request $request, $eventId)
    {
        $event = Event::find($eventId);
        if (!$event || !$event->is_numbered_seating) {
            return $this->sendError('Event not found or does not support numbered seating.');
        }

        $validated = $request->validate([
            'seat_ids' => 'required|array',
            'seat_ids.*' => 'exists:seats,id',
        ]);

        $seatIds = $validated['seat_ids'];
        $userId = $request->user()->id;

        try {
            DB::transaction(function() use ($event, $seatIds, $userId) {
                // Lock the physical seats to prevent race conditions during insertion/update
                $seats = Seat::whereIn('id', $seatIds)->lockForUpdate()->get();
                
                if ($seats->count() !== count($seatIds)) {
                    throw new \Exception('Invalid seats selected.');
                }

                foreach ($seatIds as $seatId) {
                    $reservation = SeatReservation::where('event_id', $event->id)
                                    ->where('seat_id', $seatId)
                                    ->lockForUpdate()
                                    ->first();
                    
                    if ($reservation) {
                        if ($reservation->status === 'sold') {
                            throw new \Exception("Seat ID $seatId is already sold.");
                        }
                        if ($reservation->status === 'held' && $reservation->hold_expires_at > now()) {
                            if ($reservation->user_id !== $userId) {
                                throw new \Exception("Seat ID $seatId is currently held by someone else.");
                            }
                        }
                    }

                    // Proceed to hold
                    SeatReservation::updateOrCreate(
                        ['event_id' => $event->id, 'seat_id' => $seatId],
                        [
                            'user_id' => $userId,
                            'status' => 'held',
                            'hold_expires_at' => now()->addMinutes(15),
                        ]
                    );
                }
            });

            return $this->sendResponse([], 'Seats successfully held for 15 minutes.');

        } catch (\Exception $e) {
            return $this->sendError('Failed to hold seats.', ['error' => $e->getMessage()], 409);
        }
    }

    public function releaseSeats(Request $request, $eventId)
    {
        $validated = $request->validate([
            'seat_ids' => 'required|array',
            'seat_ids.*' => 'exists:seats,id',
        ]);

        $userId = $request->user()->id;

        SeatReservation::where('event_id', $eventId)
            ->whereIn('seat_id', $validated['seat_ids'])
            ->where('user_id', $userId)
            ->where('status', 'held')
            ->update([
                'status' => 'available',
                'hold_expires_at' => null
            ]);

        return $this->sendResponse([], 'Seats released successfully.');
    }
}
