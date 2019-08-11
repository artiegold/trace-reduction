const asyncRedis = require('async-redis');
const client = asyncRedis.createClient();

client.on('error', error => console.error('redis error: ' + error));
const getTime = item => item.time;
const getLink = item => item.link;
const getBucket = time => Math.floor(time/100) * 100;
const parse = item => ({time: getTime(item), link: getLink(item)});
 
const addItem = (client, item) => {
    const parsed = parse(item);
    const bucket = getBucket(parsed.time);
    client.hset('buckets', bucket, parsed.link);
    client.zadd('bucketList', bucket, bucket);
}