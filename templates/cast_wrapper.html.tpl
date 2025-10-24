<!doctype html>
<meta charset='utf-8'>
<title>%%TITLE%%</title>
<body style='margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif'>
<h2>%%TITLE_ESC%%</h2>
<link rel='stylesheet' href='%%CSS%%'>
<script src='%%JS%%'></script>

<!-- Load centralized glue (artifacts/asciinema-glue.js) if present; fall back to inline glue when necessary -->
<script>
if (!document.querySelector('script[src="./asciinema-glue.js"]')) {
	var s = document.createElement('script');
	s.src = './asciinema-glue.js';
	s.async = true;
	document.head.appendChild(s);
}
</script>

<asciinema-player src='%%CAST_SRC%%' preload style='width:100%;height:80vh'></asciinema-player>
</body>
