<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TwoFactorResetDecisionNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $status;
    public $note;

    public function __construct($status, $note = null)
    {
        $this->status = $status;
        $this->note = $note;
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $message = (new MailMessage)
            ->subject('Two-Factor Authentication Reset ' . ucfirst($this->status));

        if ($this->status === 'approved') {
            $message->line('Your request to reset Two-Factor Authentication has been approved.');
            $message->line('Two-Factor Authentication is now disabled on your account, and all active sessions have been revoked for your security.');
            $message->line('You can now log in using just your email and password.');
            $message->action('Log In', url('/login'));
        } else {
            $message->line('Your request to reset Two-Factor Authentication has been rejected.');
            if ($this->note) {
                $message->line('Reason: ' . $this->note);
            }
            $message->line('If you believe this is an error, please contact support.');
            $message->action('Contact Support', url('/contact'));
        }

        return $message;
    }
}
