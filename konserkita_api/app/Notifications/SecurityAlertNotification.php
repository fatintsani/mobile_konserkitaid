<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\SecurityAlert;

class SecurityAlertNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $alert;

    /**
     * Create a new notification instance.
     */
    public function __construct(SecurityAlert $alert)
    {
        $this->alert = $alert;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail']; // Security Alerts are stored separately in the security_alerts table
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
                    ->error() // Red button for security alerts
                    ->subject('Security Alert: ' . $this->alert->title)
                    ->greeting('Hello ' . $notifiable->name . '!')
                    ->line($this->alert->message)
                    ->line('Type: ' . str_replace('_', ' ', strtoupper($this->alert->type)))
                    ->line('Severity: ' . strtoupper($this->alert->severity))
                    ->line('Time: ' . $this->alert->created_at->format('Y-m-d H:i:s'))
                    ->line('IP Address: ' . ($this->alert->ip_address ?? 'Unknown'))
                    ->line('Device: ' . ($this->alert->user_agent ?? 'Unknown'))
                    ->action('Review Account Security', url('/profile'))
                    ->line('If this was you, you can ignore this message. If not, please change your password immediately and contact support.');
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'alert_id' => $this->alert->id,
            'title' => $this->alert->title,
            'message' => $this->alert->message,
            'severity' => $this->alert->severity,
            'type' => 'security_alert',
        ];
    }
}
