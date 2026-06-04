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
Route::get('/banners', [\App\Http\Controllers\Api\BannerController::class, 'index']);
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

    // Organizer Dashboard
    Route::prefix('organizer')->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Api\OrganizerController::class, 'dashboard']);
        Route::get('/events', [\App\Http\Controllers\Api\OrganizerController::class, 'events']);
        Route::post('/events', [\App\Http\Controllers\Api\OrganizerController::class, 'storeEvent']);
        Route::get('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'eventDetail']);
        Route::put('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'updateEvent']);
        Route::delete('/events/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'destroyEvent']);
        Route::get('/events/{id}/sales', [\App\Http\Controllers\Api\OrganizerController::class, 'sales']);
        Route::get('/events/{id}/attendees', [\App\Http\Controllers\Api\OrganizerController::class, 'attendees']);
        Route::post('/events/{id}/ticket-types', [\App\Http\Controllers\Api\OrganizerController::class, 'storeTicketType']);
        Route::put('/ticket-types/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'updateTicketType']);
        Route::delete('/ticket-types/{id}', [\App\Http\Controllers\Api\OrganizerController::class, 'destroyTicketType']);
    });

    // Promo route
    Route::post('/promos/validate', [App\Http\Controllers\Api\PromoController::class, 'validateCode']);

    // Admin Dashboard
    Route::prefix('admin')->middleware(\App\Http\Middleware\AdminMiddleware::class)->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Api\Admin\AdminController::class, 'dashboard']);
        
        Route::get('/events', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'index']);
        Route::get('/events/{id}', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'show']);
        Route::put('/events/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'approve']);
        Route::put('/events/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'reject']);
        Route::delete('/events/{id}', [\App\Http\Controllers\Api\Admin\AdminEventController::class, 'destroy']);
        
        Route::get('/users', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'index']);
        Route::get('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'show']);
        Route::put('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'update']);
        Route::delete('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'destroy']);
        
        Route::get('/organizers', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'index']);
        Route::get('/organizers/{id}', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'show']);
        Route::put('/organizers/{id}/verify', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'verify']);
        Route::put('/organizers/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminOrganizerController::class, 'reject']);
        
        Route::get('/transactions', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'index']);
        Route::get('/transactions/{id}', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'show']);
        
        Route::get('/reports/sales', [\App\Http\Controllers\Api\Admin\AdminReportController::class, 'sales']);

        // Content Management
        Route::apiResource('banners', \App\Http\Controllers\Api\Admin\AdminBannerController::class);
        Route::apiResource('promos', \App\Http\Controllers\Api\Admin\AdminPromoController::class);
        Route::apiResource('event-categories', \App\Http\Controllers\Api\Admin\AdminCategoryController::class);
    });

    Route::get('/event-categories', [\App\Http\Controllers\Api\OrganizerController::class, 'getCategories']);

    // Checkout
    Route::post('/checkout', [CheckoutController::class, 'process']);

    // Tickets
    Route::post('/tickets/scan', [TicketController::class, 'scanTicket']);
    Route::get('/tickets', [TicketController::class, 'myTickets']);
    Route::get('/tickets/{ticket_code}', [TicketController::class, 'showQR']);
});
