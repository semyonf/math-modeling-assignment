#!/usr/bin/env node
const fs = require('fs');

createCSV('data/theor.csv', calcTheorValues());
createCSV('data/noised.csv', calcNoisedValues(calcTheorValues(), 0.05));

///////////////////////////////////////
// ВЫЧИСЛЕНИЕ ТЕОРЕТИЧЕСКИХ ЗНАЧЕНИЙ //
///////////////////////////////////////

function calcTheorValues() {
  const xt = 5, k = 4, a = 3, b1 = 1, b2 = 2;
  let y = 0, z1 = 0, z2 = 0, z3 = 0, h = 0.05, theorValues = [];

  for (let iterations = 1; iterations <= 500; iterations++) {
    z3 = (xt - z1 - (b1 + a) * z2 - (b1 + a * b1) * z3) / (a * b2);
    z2 = z2 + h * z3;
    z1 = z1 + h * z2;

    y = k * (z1 - a * z2);

    if (iterations % 20 == 0) {
      theorValues.push(y);
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
      return console.log(err);
    }

    console.info(`${filename} saved!`);
  });
}

////////////////
// ЗАШУМЛЕНИЕ //
////////////////

function calcNoisedValues(theorValues, factor) {
  const deltaY = Math.max.apply(null, theorValues) * factor;
  let noisedValues = theorValues;

  for (let i = 0; i < noisedValues.length; ++i) {
    noisedValues[i] += Math.random() * (2 * deltaY) - deltaY;
  }

  return noisedValues;
}
