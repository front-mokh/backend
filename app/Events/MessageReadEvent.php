<?php

namespace App\Events;

use App\Models\Collaboration;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageReadEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Collaboration $collaboration,
        public int $readerId,
        public string $readAt,
    ) {
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('collaboration.' . $this->collaboration->id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.read';
    }

    public function broadcastWith(): array
    {
        return [
            'collaboration_id' => $this->collaboration->id,
            'reader_id' => $this->readerId,
            'read_at' => $this->readAt,
            'brand_last_read_at' => $this->collaboration->brand_last_read_at?->toJSON(),
            'creator_last_read_at' => $this->collaboration->creator_last_read_at?->toJSON(),
            'brand_last_seen_at' => $this->collaboration->brand_last_seen_at?->toJSON(),
            'creator_last_seen_at' => $this->collaboration->creator_last_seen_at?->toJSON(),
        ];
    }
}
