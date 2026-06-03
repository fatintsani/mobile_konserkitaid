<?php

namespace App\Http\Controllers\Api;

use App\Models\Ticket;
use Illuminate\Http\Request;

class TicketController extends BaseController
{
    public function myTickets(Request $request)
    {
        $tickets = Ticket::with(['ticketType.event', 'transaction'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return $this->sendResponse($tickets, 'Tickets retrieved successfully.');
    }

    public function showQR($ticket_code)
    {
        $ticket = Ticket::with(['ticketType.event.organizer', 'user'])
            ->where('ticket_code', $ticket_code)
            ->first();

        if (is_null($ticket)) {
            return $this->sendError('Ticket not found.');
        }

        // Only allow the owner or an organizer/admin to view
        $user = auth('sanctum')->user();
        if ($user && $user->id !== $ticket->user_id && !in_array($user->role, ['organizer', 'admin', 'super_admin'])) {
            return $this->sendError('Unauthorized access to this ticket.', [], 403);
        }

        return $this->sendResponse($ticket, 'Ticket details retrieved successfully.');
    }

    public function scanTicket(Request $request)
    {
        $request->validate([
            'ticket_code' => 'required|string',
        ]);

        $user = auth('sanctum')->user();
        if (!in_array($user->role, ['organizer', 'admin', 'super_admin'])) {
            return $this->sendError('Unauthorized access.', [], 403);
        }

        $ticket = Ticket::where('ticket_code', $request->ticket_code)->first();

        if (is_null($ticket)) {
            return $this->sendError('Tiket tidak ditemukan.', [], 404);
        }

        if ($ticket->is_used) {
            return $this->sendError('Tiket sudah digunakan.', [
                'ticket_code' => $ticket->ticket_code,
                'is_used' => true,
                'checked_in_at' => $ticket->updated_at
            ], 400);
        }

        $ticket->is_used = true;
        $ticket->save();

        return $this->sendResponse([
            'ticket_code' => $ticket->ticket_code,
            'is_used' => true,
            'checked_in_at' => $ticket->updated_at
        ], 'Tiket Valid, Check-in Berhasil');
    }
}
