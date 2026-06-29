$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$port = 8139
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host ("Serving " + $root + " on http://localhost:" + $port + "/")
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = $ctx.Request.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($rel)) { $rel = 'index.html' }
    $path = Join-Path $root $rel
    if (Test-Path $path -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($path)
      $ext = [System.IO.Path]::GetExtension($path).ToLower()
      $ct = switch ($ext) {
        '.html'        { 'text/html; charset=utf-8' }
        '.js'          { 'application/javascript; charset=utf-8' }
        '.css'         { 'text/css; charset=utf-8' }
        '.webmanifest' { 'application/manifest+json; charset=utf-8' }
        '.json'        { 'application/json; charset=utf-8' }
        '.png'         { 'image/png' }
        '.svg'         { 'image/svg+xml' }
        default        { 'application/octet-stream' }
      }
      $ctx.Response.ContentType = $ct
      $ctx.Response.Headers.Add('Cache-Control', 'no-store, no-cache, must-revalidate')
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $ctx.Response.StatusCode = 404 }
    $ctx.Response.Close()
  } catch { }
}
