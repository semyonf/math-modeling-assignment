#!/usr/bin/env node
const fs = require('fs');

const
  theoreticalValues     = getFunctionValues(),
  experimentalValues005 = getExperimental(theoreticalValues, 0.05),
  experimentalValues01 = getExperimental(theoreticalValues, 0.1),
  experimentalValues02 = getExperimental(theoreticalValues, 0.2),
  optimized = optimize(function(b1, k) {
    let experimentalValues = experimentalValues02.slice();
    const modelValues = getFunctionValues(b1, k);

    let value = 0;
    for (let i = 0; i < modelValues.length; ++i) {
      value += Math.pow(experimentalValues[i] - modelValues[i], 2);
    }

    return value;
  }, 2, 5);
  // optimizedEllipse = optimize(function(x, y) {
  //   return Math.sqrt(x*x + y*y);
  // }, 4, 3),
  // optimizedRosenbrock = optimize(function(x, y) {
  //   return ((1-x)*(1-x)) + 100 * ((y - x*x) * (y - x*x));
  // }, -5, -3);

createCSV(
  'data/theor.csv',
  theoreticalValues
);

createCSV(
  'data/noised005.csv',
  experimentalValues005
);

createCSV(
  'data/noised01.csv',
  experimentalValues01
);

createCSV(
  'data/noised02.csv',
  experimentalValues02
);

createCSV(
  'data/optimized.csv',
  getFunctionValues(optimized.b1, optimized.k)
);

// console.log(optimized.steps);

createCSV(
  'data/final.csv',
  getFunctionValues(0.973, 3.984)
);

createCSV(
  'data/rnd.csv',
  checkRandomDistribution(), 'intrval, occurences'
);

function getFunctionValues(b1 = 1, k = 4) {
  const XT = 5, A = 3, B2 = 2, B1 = b1, K = k;
  let y = 0, z1 = 0, z2 = 0, z3 = 0, h = 0.05, theorValues = [];

  for (let iterations = 1; iterations <= 500; iterations++) {
    z3 = (XT - z1 - (B1 + A) * z2 - (B1 + A * b1) * z3) / (A * B2);
    z2 = z2 + h * z3;
    z1 = z1 + h * z2;

    y = K * (z1 - A * z2);

    if (iterations % 20 == 0) {
      theorValues.push(y);
    }
  }

  return theorValues;
}

function getExperimental(theorValues, factor) {
  const deltaY = Math.max.apply(null, theorValues) * factor;
  let experimentalValues = theorValues.slice();

  for (let i = 0; i < experimentalValues.length; ++i) {
    experimentalValues[i] += Math.random() * (2 * deltaY) - deltaY;
  }

  return experimentalValues;
}

function checkRandomDistribution() {
  const interval = 0.1;
  let randomNumber, distribution = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  for (var i = 0; i < 10000; ++i) {
    randomNumber = Math.random();
    ++distribution[Math.floor(randomNumber / interval)];
  }

  return distribution;
}

function optimize(callback, startX, startY) {
  let
    b1 = startX, k = startY,

    f = callback(b1, k),
    f1,
    f2 = f,

    h1 = 0.1,
    h2 = 0.1,
    steps = [],

    m = 1;

  while (true) {
    if (m == 1) {
      b1 = b1 + h1;
      f1 = callback(b1, k);

      if (f1 <= f) {
          h1 = 3 * h1;
          f = f1;
      } else {
          b1 = b1 - h1;
          h1 = -0.5 * h1;
      }

      ++m;
    } else if (m != 1) {
      k = k + h2;
      f1 = callback(b1, k);

      if (f1 <= f) {
          h2 = 3 * h2;
          f = f1;
      } else {
          k = k - h2;
          h2 = -0.5 * h2;
      }

      m = 1;
    }

    if (Math.abs(f2 - f1) < 1e-5) {
      return {b1, k, steps};
    } else {
      steps.push(`${b1}, ${k}, ${f1}`);
    }

    f2 = f1;
  }
}

function createCSV(filename, data, headers = 'x, y') {
  let output = `${headers}\n`;

  for (let i = 0; i < data.length; ++i) {
    output += `${i + 1}, ${data[i]}\n`;
  }

  fs.writeFile(filename, output, (err) => {
    if (err) {
      return console.error(err);
    }

    console.info(`${filename} done!`);
  });
}
