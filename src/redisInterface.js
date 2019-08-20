const asyncRedis = require("async-redis");
let client;

async function init() {
  client = await asyncRedis.createClient();
  client.on("error", error => console.error("redis error: " + error));
  await client.flushall();
}

async function pushItem(bucket, link) {
  await client.zadd("bucketList", bucket, bucket);
  await client.sadd(bucket, link);
}

async function result(f) {
  let indicator = null;
  while (indicator !== "0") {
    const bucketsRaw = await client.zscan("bucketList", 0);
    indicator = bucketsRaw[0];
    const bucket2s = Array.from(new Set(bucketsRaw[1]));
    bucket2s.forEach(async k => {
      (await client.smembers(k)).forEach(v => f(k,v));
    });
    console.log(indicator);
  }
  return true;
}

module.exports = {
  init,
  pushItem,
  result
};
