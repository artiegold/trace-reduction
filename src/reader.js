const nReadlines = require('n-readlines');

const process = (filenames, func) => {
    filenames.forEach(f => {
        const reader = new nReadlines(f);
        let line;
        while (line = reader.next()) {
            console.log(`applying func to ${line}`);
            console.log(rslt);
        }
    })
}

module.exports = {process};