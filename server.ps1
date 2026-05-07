$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:3000/")
$listener.Start()
Write-Host "Server läuft auf http://localhost:3000"

$mimeTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css"
  ".js"   = "application/javascript"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  $ctx  = $listener.GetContext()
  $req  = $ctx.Request
  $resp = $ctx.Response

  $path = $req.Url.LocalPath -replace "/", "\"
  if ($path -eq "\") { $path = "\index.html" }
  $file = Join-Path $root $path.TrimStart("\")

  $resp.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
  $resp.Headers.Add("Pragma", "no-cache")
  $resp.Headers.Add("Expires", "0")

  if (Test-Path $file -PathType Leaf) {
    $ext  = [System.IO.Path]::GetExtension($file).ToLower()
    $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $resp.ContentType      = $mime
    $resp.ContentLength64  = $bytes.Length
    $resp.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $resp.StatusCode = 404
  }
  $resp.Close()
}
