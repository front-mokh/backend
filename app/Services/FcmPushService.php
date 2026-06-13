<?php

namespace App\Services;

use App\Models\PushDeviceToken;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmPushService
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function send(
        PushDeviceToken $deviceToken,
        string $title,
        string $body,
        array $data = []
    ): void {
        $projectId = config('services.firebase.project_id');
        if (! $projectId) {
            Log::debug('FCM push skipped: missing Firebase project id.');

            return;
        }

        $accessToken = $this->accessToken();
        if (! $accessToken) {
            Log::debug('FCM push skipped: missing Firebase access token.');

            return;
        }

        $response = Http::withToken($accessToken)
            ->acceptJson()
            ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                'message' => [
                    'token' => $deviceToken->token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $this->stringData($data),
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'channel_id' => 'default',
                            'sound' => 'default',
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ],
            ]);

        if ($response->successful()) {
            $deviceToken->forceFill(['last_used_at' => now()])->save();

            return;
        }

        Log::warning('FCM push notification failed.', [
            'device_token_id' => $deviceToken->id,
            'status' => $response->status(),
            'body' => $response->json() ?? $response->body(),
        ]);

        if ($this->isInvalidTokenResponse($response->json() ?? [])) {
            $deviceToken->delete();
        }
    }

    private function accessToken(): ?string
    {
        $projectId = config('services.firebase.project_id');
        $cacheKey = "firebase_access_token:{$projectId}";
        $cached = Cache::get($cacheKey);
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $credentials = $this->credentials();
        if (! $credentials) {
            return null;
        }

        $jwt = $this->jwt($credentials['client_email'], $credentials['private_key']);
        if (! $jwt) {
            return null;
        }

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if (! $response->successful()) {
            Log::error('Unable to fetch Firebase access token.', [
                'status' => $response->status(),
                'body' => $response->json() ?? $response->body(),
            ]);

            return null;
        }

        $token = $response->json('access_token');
        if (! is_string($token) || $token === '') {
            return null;
        }

        $expiresIn = (int) ($response->json('expires_in') ?? 3600);
        Cache::put($cacheKey, $token, now()->addSeconds(max(60, $expiresIn - 60)));

        return $token;
    }

    private function credentials(): ?array
    {
        $json = config('services.firebase.service_account_json');
        if (is_string($json) && $json !== '') {
            $decoded = $this->decodeServiceAccountJson($json);
            if ($decoded) {
                return $decoded;
            }
        }

        $path = config('services.firebase.service_account_path');
        if (is_string($path) && $path !== '') {
            $fullPath = str_starts_with($path, '/') ? $path : base_path($path);
            if (is_file($fullPath)) {
                $decoded = $this->decodeServiceAccountJson((string) file_get_contents($fullPath));
                if ($decoded) {
                    return $decoded;
                }
            }
        }

        $clientEmail = config('services.firebase.client_email');
        $privateKey = config('services.firebase.private_key');
        if (is_string($clientEmail) && $clientEmail !== '' && is_string($privateKey) && $privateKey !== '') {
            return [
                'client_email' => $clientEmail,
                'private_key' => str_replace('\\n', "\n", $privateKey),
            ];
        }

        return null;
    }

    private function decodeServiceAccountJson(string $value): ?array
    {
        $json = trim($value);
        if (! str_starts_with($json, '{')) {
            $decoded = base64_decode($json, true);
            if (is_string($decoded) && $decoded !== '') {
                $json = $decoded;
            }
        }

        $data = json_decode($json, true);
        if (! is_array($data)) {
            return null;
        }

        $clientEmail = $data['client_email'] ?? null;
        $privateKey = $data['private_key'] ?? null;
        if (! is_string($clientEmail) || ! is_string($privateKey)) {
            return null;
        }

        return [
            'client_email' => $clientEmail,
            'private_key' => str_replace('\\n', "\n", $privateKey),
        ];
    }

    private function jwt(string $clientEmail, string $privateKey): ?string
    {
        $now = time();
        $header = $this->base64UrlEncode(json_encode([
            'alg' => 'RS256',
            'typ' => 'JWT',
        ], JSON_THROW_ON_ERROR));
        $claims = $this->base64UrlEncode(json_encode([
            'iss' => $clientEmail,
            'scope' => self::SCOPE,
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ], JSON_THROW_ON_ERROR));

        $unsigned = "{$header}.{$claims}";
        $signature = '';
        $signed = openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (! $signed) {
            Log::error('Unable to sign Firebase service account JWT.');

            return null;
        }

        return $unsigned.'.'.$this->base64UrlEncode($signature);
    }

    private function stringData(array $data): array
    {
        $result = [];
        foreach ($data as $key => $value) {
            if ($value === null) {
                continue;
            }
            $result[(string) $key] = is_scalar($value)
                ? (string) $value
                : json_encode($value, JSON_THROW_ON_ERROR);
        }

        return $result;
    }

    private function isInvalidTokenResponse(array $body): bool
    {
        $status = data_get($body, 'error.status');
        $message = data_get($body, 'error.message', '');

        return in_array($status, ['INVALID_ARGUMENT', 'NOT_FOUND', 'UNREGISTERED'], true)
            || str_contains((string) $message, 'registration token is not a valid')
            || str_contains((string) $message, 'Requested entity was not found');
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
