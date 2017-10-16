#!/usr/local/bin/node

let xt = 5,
    k = 4,
    a = 3,
    b1 = 1,
    b2 = 2,

    y = 0,
    z1 = 0,
    z2 = 0,
    z3 = 0,
    h = 0.1,

    iterations = 500,

    result = '';

while (iterations) {
    z3 = (xt - z1 - (b1 + a) * z2 - (b1 + a * b1) * z3) / (a * b2);
    z2 = z2 + h * z3;
    z1 = z1 + h * z2;

    y = k * (z1 - a * z2);

    if (iterations % 10 == 0) {
        result += `${(1000 - iterations) * h} ${y}\n`;
    }

    --iterations;
}

console.log(result);
