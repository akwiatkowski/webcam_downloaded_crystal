$(document).ready ->
  if $("#content")
    $.ajax
      url: "data.json"
      success: (e) =>
        console.log(e)
