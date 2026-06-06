<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Organizer;
use Illuminate\Http\Request;

class AdminOrganizerController extends BaseController
{
    public function index(Request $request)
    {
        $organizers = Organizer::with('user')->orderBy('created_at', 'desc')->paginate(10);
        return $this->sendResponse($organizers, 'Organizers retrieved successfully.');
    }

    public function show($id)
    {
        $organizer = Organizer::with('user')->find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        return $this->sendResponse($organizer, 'Organizer details retrieved successfully.');
    }

    public function verify($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $organizer->is_verified = true;
        $organizer->save();

        return $this->sendResponse($organizer, 'Organizer verified successfully.');
    }

    public function reject($id)
    {
        $organizer = Organizer::find($id);

        if (!$organizer) {
            return $this->sendError('Organizer not found.', [], 404);
        }

        $organizer->is_verified = false;
        $organizer->save();

        return $this->sendResponse($organizer, 'Organizer rejected.');
    }
}
