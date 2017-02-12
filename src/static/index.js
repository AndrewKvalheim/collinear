require('./styles/main.scss');

var Elm = require('../elm/Main');

var app = Elm.Main.embed(document.getElementById('main'), {
  'hot': false
});

if (app.hot !== undefined) {
  app.hot.subscribe(function(event, context) {
    if (event === 'swap') {
      context.flags.hot = true;
    }
  });
}
