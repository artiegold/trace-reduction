const asyncRedis = require("async-redis");
const client = asyncRedis.createClient();

client.on("error", error => console.error("redis error: " + error));
const getTime = item => item.time;
const getLink = item => item.link;
const getBucket = time => Math.floor(time / 100) * 100;
const parse = item => item;

const addItem = async (client, item) => {
  const parsed = parse(item);
  const bucket = getBucket(parsed.time);

  console.log("link: " + parsed.link + " bucket: " + bucket);

  try {
    await client.hset("buckets", bucket, parsed.link);
    await client.zadd("bucketList", bucket, bucket);
  } catch (e) {
    console.error("redis error: " + e);
  }
  return client;
};

const sample = () => {
  [
    { time: 23425332, link: "linkone" },
    { time: 23425300, link: "linktwo" },
    { time: 23532341, link: "linkthree" }
  ].reduce(addItem, client);

  //console.log(client);
};

module.exports = {
  sample
};
