const nowUnix = Math.round((new Date()).getTime() / 1000);

const fiveHoursAgo = nowUnix - 18000;

const getRandomRange = (low, high) => Math.round(Math.random() * (high - low)) + low;

const getRandomTime = () => getRandomRange(fiveHoursAgo, nowUnix);

const getRandomLink = () => "link-" + getRandomRange(1, 1001);

for (i = 0; i < 50000; i = i + 1) {
	console.log(`${getRandomTime()},${getRandomLink()}`);
}

