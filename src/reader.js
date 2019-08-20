const nReadlines = const lineByLine = require('n-readlines');

const process = (filenames, func) => {
    filenames.forEach(f => {
        const reader = new nReadLines(filename);
        let line;
        while (line = reader.next()) {
            func(line);
        }
    })
}