<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Venue;
use App\Models\VenueSection;
use App\Models\Seat;
use App\Models\Event;
use App\Models\EventSeatMap;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminVenueController extends BaseController
{
    public function index()
    {
        $venues = Venue::with('sections')->latest()->get();
        return $this->sendResponse($venues, 'Venues retrieved successfully.');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'city' => 'required|string|max:255',
            'address' => 'required|string',
            'capacity' => 'nullable|integer',
            'status' => 'required|in:active,inactive',
        ]);

        $venue = Venue::create($validated);
        return $this->sendResponse($venue, 'Venue created successfully.');
    }

    public function show($id)
    {
        $venue = Venue::with(['sections.seats'])->find($id);
        if (!$venue) {
            return $this->sendError('Venue not found.');
        }
        return $this->sendResponse($venue, 'Venue retrieved successfully.');
    }

    public function update(Request $request, $id)
    {
        $venue = Venue::find($id);
        if (!$venue) {
            return $this->sendError('Venue not found.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'city' => 'required|string|max:255',
            'address' => 'required|string',
            'capacity' => 'nullable|integer',
            'status' => 'required|in:active,inactive',
        ]);

        $venue->update($validated);
        return $this->sendResponse($venue, 'Venue updated successfully.');
    }

    public function destroy($id)
    {
        $venue = Venue::find($id);
        if (!$venue) {
            return $this->sendError('Venue not found.');
        }

        $venue->delete();
        return $this->sendResponse([], 'Venue deleted successfully.');
    }

    public function storeSection(Request $request, $id)
    {
        $venue = Venue::find($id);
        if (!$venue) {
            return $this->sendError('Venue not found.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'label' => 'required|string|max:50',
            'row_count' => 'required|integer|min:1',
            'seats_per_row' => 'required|integer|min:1',
            'status' => 'required|in:active,inactive',
        ]);

        $section = $venue->sections()->create($validated);
        return $this->sendResponse($section, 'Venue section created successfully.');
    }

    public function generateSeats(Request $request, $sectionId)
    {
        $section = VenueSection::find($sectionId);
        if (!$section) {
            return $this->sendError('Section not found.');
        }

        DB::beginTransaction();
        try {
            // Delete existing seats for this section if regenerating
            Seat::where('venue_section_id', $section->id)->delete();

            $seatsToInsert = [];
            $rows = range('A', 'Z'); // Support up to 26 rows easily
            
            for ($r = 0; $r < $section->row_count; $r++) {
                $rowLabel = $rows[$r] ?? 'R' . ($r + 1);
                
                for ($s = 1; $s <= $section->seats_per_row; $s++) {
                    $seatCode = "{$section->label}-{$rowLabel}-{$s}";
                    $seatsToInsert[] = [
                        'venue_section_id' => $section->id,
                        'row_label' => $rowLabel,
                        'seat_number' => $s,
                        'seat_code' => $seatCode,
                        'status' => 'active',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
            }

            Seat::insert($seatsToInsert);
            DB::commit();

            return $this->sendResponse(['total_seats' => count($seatsToInsert)], 'Seats generated successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Failed to generate seats.', ['error' => $e->getMessage()]);
        }
    }

    public function assignSeatMap(Request $request, $eventId)
    {
        $event = Event::find($eventId);
        if (!$event) {
            return $this->sendError('Event not found.');
        }

        $validated = $request->validate([
            'venue_id' => 'required|exists:venues,id',
        ]);

        // Create or update
        $seatMap = EventSeatMap::updateOrCreate(
            ['event_id' => $event->id],
            ['venue_id' => $validated['venue_id']]
        );

        return $this->sendResponse($seatMap, 'Seat map assigned successfully.');
    }
}
