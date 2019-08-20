const nReadlines = require('n-readlines');

const process = (filenames, func) => {
    filenames.forEach(f => {
        const reader = new nReadlines(f);
        let line;
        while (line = reader.next()) {
            func(line);
        }
    })
}

module.exports = {process};