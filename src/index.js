const asyncRedis = require('async-redis');
const client = asyncRedis.createClient();

client.on('error', error => console.error('redis error: ' + error));
const getTime = item => item.time;
const getLink = item => item.link;
const getBucket = time => Math.floor(time/100) * 100;
const parse = item => ({time: getTime(item), link: getLink(item)});
 
const addItem = async (client, item) => {
    const parsed = parse(item);
    const bucket = getBucket(parsed.time);
    
    try {const asyncRedis = require('async-redis');
    const client = asyncRedis.createClient();
    
    client.on('error', error => console.error('redis error: ' + error));
    const getTime = item => item.time;
    const getLink = item => item.link;
    const getBucket = time => Math.floor(time/100) * 100;
    const parse = item => ({time: getTime(item), link: getLink(item)});
     
    const addItem = async (client, item) => {
        const parsed = parse(item);
        const bucket = getBucket(parsed.time);
        
        try {
            await client.hset('buckets', bucket, parsed.link);
            await client.zadd('bucketList', bucket, bucket);
        } catch(e) {
            console.error('redis error: ' + e);
        }
    }
    
    [
        {time: 23425332, link: 'linkone'},
        {time: 23425300, link: 'linktwo'},
        {time: 23532341, link: 'linkthree'}
    ].reduce(addItem, client);
    
    console.log(client);
    const asyncRedis = require('async-redis');
    const client = asyncRedis.createClient();
    
    client.on('error', error => console.error('redis error: ' + error));
    const getTime = item => item.time;
    const getLink = item => item.link;
    const getBucket = time => Math.floor(time/100) * 100;
    const parse = item => ({time: getTime(item), link: getLink(item)});
     
    const addItem = async (client, item) => {
        console.log('client/link:' + client + '/' + item.link);
        const parsed = parse(item);
        const bucket = getBucket(parsed.time);
        
        try {
        await client.hset('buckets', bucket, parsed.link);
        await client.zadd('bucketList', bucket, bucket);
        } catch(e) {
            console.error('redis error: ' + e);
        }
    }
    
    [
        {time: 23425332, link: 'linkone'},
        {time: 23425300, link: 'linktwo'},
        {time: 23532341, link: 'linkthree'}
    ].reduce(addItem, client);
    
    console.log(client);
        await client.hset('buckets', bucket, parsed.link);
        await client.zadd('bucketList', bucket, bucket);
    } catch(e) {
        console.error('redis error: ' + e);
    }
}

[
    {time: 23425332, link: 'linkone'},
    {time: 23425300, link: 'linktwo'},
    {time: 23532341, link: 'linkthree'}
].reduce(addItem, client);

console.log(client);
const asyncRedis = require('async-redis');
const client = asyncRedis.createClient();

client.on('error', error => console.error('redis error: ' + error));
const getTime = item => item.time;
const getLink = item => item.link;
const getBucket = time => Math.floor(time/100) * 100;
const parse = item => ({time: getTime(item), link: getLink(item)});
 
const addItem = async (client, item) => {
    const parsed = parse(item);
    const bucket = getBucket(parsed.time);
    
    try {
    await client.hset('buckets', bucket, parsed.link);
    await client.zadd('bucketList', bucket, bucket);
    } catch(e) {
        console.error('redis error: ' + e);
    }
}

[
    {time: 23425332, link: 'linkone'},
    {time: 23425300, link: 'linktwo'},
    {time: 23532341, link: 'linkthree'}
].reduce(addItem, client);

console.log(client);