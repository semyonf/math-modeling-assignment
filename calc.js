#!/usr/bin/env node
;(function (undefined) {
  'use strict';

  const fs = require('fs');

  const
    theoreticalValues = getModel(),

    experimental1 = getExperimental(theoreticalValues, 0.05),
    experimental2  = getExperimental(theoreticalValues, 0.1),
    experimental3  = getExperimental(theoreticalValues, 0.2);

  /**
   * CF
   */
  optimize(function(b1, k) {
    const
      modelValues = getModel(b1, k),
      experimentalValues = experimental1;

    const cf = experimentalValues.reduce(function(sum, current, i) {
      return sum + Math.pow(current - modelValues[i], 2);
    }, 0);

    return cf;
  }, 2, 5, (b1, k, steps) => {
    createCSV(
      'data/optimized.csv',
      getModel(b1, k)
    );

    console.info(steps);
  });

  /**
   * Ellipse (precomputed)
   */
  // optimize(function(x, y) {
  //   return Math.sqrt(x*x + y*y);
  // }, 4, 3, function (x, y) {});

  /**
   * Rosenbrock (precomputed)
   */
  // optimize(function(x, y) {
  //   return ((1-x)*(1-x)) + 100 * ((y - x*x) * (y - x*x));
  // }, 5, 3, function (x, y) {});

  createCSV('data/theor.csv', theoreticalValues);
  createCSV('data/noised005.csv', experimental1);
  createCSV('data/noised01.csv', experimental2);
  createCSV('data/noised02.csv', experimental3);
  createCSV('data/final.csv', getModel(0.973, 3.984));
  createCSV('data/rnd.csv', checkRandomDistribution(), 'intrval, occurences');

  function getModel(b1 = 1, k = 4) {
    const XT = 5, A = 3, B2 = 2, B1 = b1, K = k;
    let y = 0, z1 = 0, z2 = 0, z3 = 0, h = 0.05, theorValues = [];

    for (let i = 1; i <= 500; ++i) {
      z3 = (XT - z1 - (B1 + A) * z2 - (B1 + A * b1) * z3) / (A * B2);
      z2 = z2 + h * z3;
      z1 = z1 + h * z2;

      y = K * (z1 - A * z2);

      if (i % 20 == 0) {
        theorValues.push(y);
      }
    }

    return theorValues;
  }

  function getExperimental(theorValues, factor) {
    const deltaY = Math.max.apply(null, theorValues) * factor;

    return theorValues.map(function(value) {
        return value += Math.random() * (2 * deltaY) - deltaY;
      }
    );
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

  function optimize(func, startX, startY, callback) {
    let
      x = startX, y = startY,

      f = func(x, y),
      f1,
      f2 = f,

      deltaX = 0.1,
      deltaY = 0.1,
      steps = [],

      m = 1;

    while (true) {
      if (m == 1) {
        x += deltaX;
        f1 = func(x, y);

        if (f1 <= f) {
            deltaX *= 3;
            f = f1;
        } else {
            x -= deltaX;
            deltaX *= -0.5;
        }

        ++m;
      } else if (m != 1) {
        y += deltaY;
        f1 = func(x, y);

        if (f1 <= f) {
            deltaY *= 3;
            f = f1;
        } else {
            y -= deltaY;
            deltaY *= -0.5;
        }

        m = 1;
      }

      if (Math.abs(f2 - f1) < 1e-5) {
        callback(x, y, steps);

        return {x, y, steps};
      } else {
        steps.push(`${x}, ${y}, ${f1}`);
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
})();
