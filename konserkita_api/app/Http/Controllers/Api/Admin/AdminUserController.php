<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminUserController extends BaseController
{
    public function index(Request $request)
    {
        $role = $request->query('role');

        $query = User::query();

        if ($role) {
            $query->where('role', $role);
        }

        $users = $query->orderBy('created_at', 'desc')->get();

        return $this->sendResponse($users, 'Users retrieved successfully.');
    }

    public function show($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        return $this->sendResponse($user, 'User details retrieved successfully.');
    }

    public function update(Request $request, $id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        $validator = Validator::make($request->all(), [
            'role' => 'required|in:customer,organizer,admin,super_admin',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error.', $validator->errors(), 400);
        }

        // Prevent modifying super_admin if not super_admin (basic check)
        $currentUser = $request->user();
        if ($user->role === 'super_admin' && $currentUser->role !== 'super_admin') {
            return $this->sendError('Unauthorized to modify super_admin.', [], 403);
        }

        $user->role = $request->role;
        $user->save();

        return $this->sendResponse($user, 'User role updated successfully.');
    }

    public function destroy($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->sendError('User not found.', [], 404);
        }

        $currentUser = request()->user();
        if ($user->id === $currentUser->id) {
            return $this->sendError('Cannot delete yourself.', [], 400);
        }

        // Check if user has transactions or tickets
        $hasTransactions = \App\Models\Transaction::where('user_id', $user->id)->exists();
        $hasTickets = \App\Models\Ticket::where('user_id', $user->id)->exists();

        if ($hasTransactions || $hasTickets) {
            return $this->sendError('Cannot delete user. User has active transactions or tickets.', [], 400);
        }

        $user->delete();

        return $this->sendResponse([], 'User deleted successfully.');
    }
}
