const reducer = (add) => (state, val) => add(val, state);

const r = reducer((x, y) => x + y);

console.log([1,2,3].reduce(reducer));