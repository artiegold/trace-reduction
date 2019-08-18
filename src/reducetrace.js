const asyncRedis = require("async-redis");
let client;

const getBucket = time => Math.floor(time / 100) * 100;

async function init() {
  client = asyncRedis.createClient();
  client.on("error", error => console.error("redis error: " + error));
  await client.flushall();
}

async function pushItem(bucket, link) {
  await client.zadd("bucketList", bucket, bucket);
  await client.sadd(bucket, link);
}

async function result() {
  const bucketsRaw = await client.zscan('bucketList', 0);
  const bucket2s = Array.from(new Set(bucketsRaw[1]));
  bucket2s.forEach(async k => {
    const values = await client.smembers(k);
    values.forEach(v => console.log(k + ' ' + v));
  });
};

async function sample() {
  await init();
  await[
    { time: 23425332, link: "linkone" },
    { time: 23425300, link: "linktwo" },
    { time: 23532301, link: "linkthree" },
    { time: 23532341, link: "linkthree" },
    { time: 23532345, link: "linkone" },
    { time: 23532453, link: "linktwo"}
  ].forEach(item => {
    pushItem(getBucket(item.time), item.link);
    console.log("link: " + item.link + " pushed to bucket: " + getBucket(item.time));
  });
  await result();
}

module.exports = {
  sample
};
