<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Services\PushNotificationService;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'message',
        'type',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected static function booted()
    {
        static::created(function ($notification) {
            try {
                $pushService = app(PushNotificationService::class);
                $pushService->sendToUser(
                    $notification->user_id,
                    $notification->title,
                    $notification->message,
                    ['type' => $notification->type, 'notification_id' => (string) $notification->id]
                );
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Auto-push failed: ' . $e->getMessage());
            }
        });
    }
}
