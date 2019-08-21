const { sample, parser } = require('./src/reducetrace');
const { process } = require('./src/reader');


process(['./utils/logs/file1', './utils/logs/file2'], item => console.log(parser(300)(item)));


// (async () => {
//     console.log(await sample());
// })();
