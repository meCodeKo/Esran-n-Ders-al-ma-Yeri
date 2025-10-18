$folder = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:8000/"
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
    Write-Host "Serving $folder on $prefix"
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $path = $request.Url.AbsolutePath.TrimStart('/')
        if ($path -eq '') { $path = 'index.html' }
        $file = Join-Path $folder $path
        if (-not (Test-Path $file)) {
            $context.Response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
            $context.Response.OutputStream.Write($buffer,0,$buffer.Length)
            $context.Response.Close()
            continue
        }
        try {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            $mime = switch ($ext) {
                '.html' { 'text/html' }
                '.htm' { 'text/html' }
                '.css' { 'text/css' }
                '.js' { 'application/javascript' }
                '.png' { 'image/png' }
                '.jpg' { 'image/jpeg' }
                '.jpeg' { 'image/jpeg' }
                '.gif' { 'image/gif' }
                '.mp3' { 'audio/mpeg' }
                '.mp4' { 'video/mp4' }
                default { 'application/octet-stream' }
            }
            $context.Response.ContentType = $mime
            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
            $context.Response.Close()
        } catch {
            $context.Response.StatusCode = 500
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('500 Internal Server Error')
            $context.Response.OutputStream.Write($buffer,0,$buffer.Length)
            $context.Response.Close()
        }
    }
} finally {
    if ($listener -and $listener.IsListening) { $listener.Stop() }
}
