const { sample } = require('./src/reducetrace');

const done = (() => sample())().then(console.log('done'));
