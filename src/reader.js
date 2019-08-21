const nReadlines = require('n-readlines');

const process = (filenames, func) => {
    filenames.forEach(f => {
        const reader = new nReadlines(f);
        let line;
        while (line = reader.next()) {
            console.log(typeof line);
            console.log('/' + line + '/');
            console.log(`applying func to ${line}`);
            const rslt = func(line.toString('ascii'));
            console.log(rslt);
        }
    })
}

module.exports = {process};