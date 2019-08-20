const { sample } = require('./src/reducetrace');
const { process } = require('./src/reader');

process(['./utils/logs/file1', './utils/logs/file2'], item => {console.log(item.toString('ascii'))});


// (async () => {
//     console.log(await sample());
// })();
