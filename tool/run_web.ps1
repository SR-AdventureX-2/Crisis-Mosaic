param(
  [string]$HostName = "127.0.0.1",
  [int]$Port = 52123,
  [string]$ApiBaseUrl = "http://127.0.0.1:52125"
)

flutter run `
  -d web-server `
  --web-hostname $HostName `
  --web-port $Port `
  --no-web-resources-cdn `
  --dart-define="CRISIS_MOSAIC_API_BASE_URL=$ApiBaseUrl"
