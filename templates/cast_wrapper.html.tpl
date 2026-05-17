<!doctype html>
<meta charset="utf-8">
<title>%%TITLE_ESC%%</title>

<link rel="stylesheet" href="%%CSS%%">
<script src="%%JS%%"></script>

<body style="margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif">
<h2>%%TITLE_ESC%%</h2>

<div id="player"></div>

<script>
window.addEventListener("load", () => {
  if (!window.AsciinemaPlayer) {
    document.body.insertAdjacentHTML(
      "beforeend",
      "<pre style='color:red'>ERROR: AsciinemaPlayer API not found.</pre>"
    );
    return;
  }

  AsciinemaPlayer.create("%%CAST_SRC%%", document.getElementById("player"), {
    preload: true,
    rows: 40
  });
});
</script>

</body>