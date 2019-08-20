const {pushItem, result, init} = require('./redisInterface');
let parserFunc;

function initMe(parser) {
  parserFunc = parser;
  init();
}

const parser = (secondsPerBucket) => (item) => ({
  time: Math.floor(item.time / secondsPerBucket) * secondsPerBucket,
  link: item.link 
});

const showResults = (k, v) => console.log(`time: ${k} link: ${v}`);

const bucketize = (item) => {
  const pieces = item.split(',');
  return {time: pieces[0], link: pieces[1]};
}

async function sample() {
  await initMe(parser(300));
  [
    { time: 23425332, link: "linkone" },
    { time: 23425300, link: "linktwo" },
    { time: 23534301, link: "linkthree" },
    { time: 23537341, link: "linkthree" },
    { time: 23532345, link: "linkone" },
    { time: 23532453, link: "linktwo"}
  ].forEach(item => {
    const parsed = parserFunc(item);
    pushItem(parsed.time, parsed.link);
  });
  return result(showResults);
}

module.exports = {
  sample
};
