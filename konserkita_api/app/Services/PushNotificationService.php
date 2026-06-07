<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use App\Models\DeviceToken;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    protected $messaging;

    public function __construct()
    {
        try {
            // Jika ada kredensial firebase di environment atau config
            $factory = (new Factory)
                ->withServiceAccount(config('firebase.credentials.file', storage_path('app/firebase/google-services.json')));
            
            $this->messaging = $factory->createMessaging();
        } catch (\Exception $e) {
            Log::error('Firebase initialization failed: ' . $e->getMessage());
        }
    }

    public function sendToUser($userId, $title, $body, $data = [])
    {
        $tokens = DeviceToken::where('user_id', $userId)->pluck('token')->toArray();
        if (empty($tokens)) {
            return false;
        }

        return $this->sendToTokens($tokens, $title, $body, $data);
    }

    public function sendToRole($role, $title, $body, $data = [])
    {
        $tokens = DeviceToken::whereHas('user', function ($q) use ($role) {
            $q->where('role', $role);
        })->pluck('token')->toArray();

        if (empty($tokens)) {
            return false;
        }

        return $this->sendToTokens($tokens, $title, $body, $data);
    }

    public function sendToAll($title, $body, $data = [])
    {
        // Batch processing if too many
        DeviceToken::chunk(500, function ($tokens) use ($title, $body, $data) {
            $tokenStrings = $tokens->pluck('token')->toArray();
            $this->sendToTokens($tokenStrings, $title, $body, $data);
        });

        return true;
    }

    protected function sendToTokens(array $tokens, $title, $body, $data = [])
    {
        if (!$this->messaging) {
            Log::warning('FCM messaging is not initialized.');
            return false;
        }

        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData($data);

        try {
            $report = $this->messaging->sendMulticast($message, $tokens);
            
            if ($report->hasFailures()) {
                $invalidTokens = [];
                foreach ($report->failures()->getItems() as $failure) {
                    $invalidTokens[] = $failure->target()->value();
                }
                
                // Remove invalid tokens
                if (!empty($invalidTokens)) {
                    DeviceToken::whereIn('token', $invalidTokens)->delete();
                }
            }

            return true;
        } catch (\Exception $e) {
            Log::error('FCM send failed: ' . $e->getMessage());
            return false;
        }
    }
}
