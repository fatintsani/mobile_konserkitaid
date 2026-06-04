<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\WishlistController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);

// Midtrans Webhook Notification
Route::post('/payment/notification', [PaymentController::class, 'notificationHandler']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Transactions
    Route::get('/transactions', [App\Http\Controllers\Api\TransactionController::class, 'index']);
    Route::get('/transactions/{id}', [App\Http\Controllers\Api\TransactionController::class, 'show']);

    // Wishlist
    Route::get('/wishlists', [WishlistController::class, 'index']);
    Route::post('/wishlists', [WishlistController::class, 'store']);
    Route::delete('/wishlists/{id}', [WishlistController::class, 'destroy']);

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);

    // Checkout
    Route::post('/checkout', [CheckoutController::class, 'process']);

    // Tickets
    Route::post('/tickets/scan', [TicketController::class, 'scanTicket']);
    Route::get('/tickets', [TicketController::class, 'myTickets']);
    Route::get('/tickets/{ticket_code}', [TicketController::class, 'showQR']);
});
