<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliverableSubmission extends Model
{
    protected $fillable = [
        'collaboration_id',
        'deliverable_type_id',
        'url',
        'attachment',
        'status',
        'feedback',
    ];

    public function getAttachmentAttribute($value)
    {
        return $value ? asset('storage/' . $value) : null;
    }

    public function collaboration()
    {
        return $this->belongsTo(Collaboration::class);
    }

    public function deliverableType()
    {
        return $this->belongsTo(DeliverableType::class);
    }
}
