// Generated by CoffeeScript 1.9.2
(function() {
  $(document).ready(function() {
    if ($("#content")) {
      return $.ajax({
        url: "data.json",
        success: (function(_this) {
          return function(e) {
            return console.log(e);
          };
        })(this)
      });
    }
  });

}).call(this);
