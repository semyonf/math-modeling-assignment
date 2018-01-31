#!/usr/bin/env node
const fs = require('fs');

const
  theorValues = calcTheor(),
  noisedValues005 = calcNoised(theorValues, 0.05);

createCSV('data/theor.csv', theorValues);
createCSV('data/noised.csv', noisedValues005);
// createCSV('data/optimized.csv', calcTheor(1.481, 5.7368));
// createCSV('data/optimized.csv', calcTheor(1.281, 3.9368));
// createCSV('data/optimized.csv', calcTheor(2.0593, 4.2006));

// optimize();
// process.exit(1);

///////////////////////////////////////
// ВЫЧИСЛЕНИЕ ТЕОРЕТИЧЕСКИХ ЗНАЧЕНИЙ //
///////////////////////////////////////

function calcTheor(b1 = 1, k = 4, addedNoise = null) {
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

  if (addedNoise) {
    let res = 0;
    for (let i = 0; i < theorValues.length; ++i) {
      res += Math.pow(theorValues[i] - addedNoise[i], 2);
    }
  }

  return theorValues;
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

    console.info(`${filename} saved!`);
  });
}

////////////////
// ЗАШУМЛЕНИЕ //
////////////////

function calcNoised(theorValues, factor) {
  const deltaY = Math.max.apply(null, theorValues) * factor;
  let noisedValues = theorValues.slice();

  for (let i = 0; i < noisedValues.length; ++i) {
    noisedValues[i] += Math.random() * (2 * deltaY) - deltaY;
  }

  return noisedValues;
}

/////////////////
// ОПТИМИЗАЦИЯ //
/////////////////

function optimize() {
  let b1 = 2, k = 5, f, f1, f2, h1 = 0.1, h2 = 0.1;

  const noisedValues = calcNoised(calcTheor(), 0.05);

  let m = 1;

  f = calcTheor(b1, k, noisedValues);
  f2 = f;

  while (true) {
    if (m == 1) {
      b1 = b1 + h1;
      f1 = calcTheor(b1, k, noisedValues); // insert function
      if (f1 <= f) {
          h1 = 3 * h1;
          f = f1;
      } else {
          b1 = b1 - h1;
          h1 = -0.5 * h1;
      }
      ++m;
    } else if (m == 2) {
      k = k + h2;
      f1 = calcTheor(b1, k, noisedValues); // insert function
      if (f1 <= f) {
          h2 = 3 * h2;
          f = f1;
      } else {
          k = k - h2;
          h2 = -0.5 * h2;
      }
      m = 1;
    }

    console.log(b1, k);

    if (Math.abs(f2 - f1) < 0.05) {
      break;
      process.exit(1);
    }

    f2 = f1;
  }
}
