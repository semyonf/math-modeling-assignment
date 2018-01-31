#!/usr/bin/env node

/**
 * Внешние модули
 */
const fs = require('fs');

/**
 * Вычисление векторов теоретических и экспериментальных значений
 */
const
  theoreticalValues     = getFunctionValues(),
  experimentalValues005 = getExperimental(theoreticalValues, 0.05);
  // тут надо еще с другими коэффициентами (0.1 и 0.2)

/**
 * Отыскание неизвестных b1 и k путём оптимизации экспериментальных значений
 * и поиска наименьшей целевой функции, или как сказать? Я должен их как-то
 * усреднить для всех вариантов коэффициентов?
 */
const optimized = optimize(experimentalValues005);

/**
 * Тут просто сохраняются вектора в CSV-таблицы для отчёта
 */
createCSV('data/theor.csv', theoreticalValues);
createCSV('data/noised005.csv', experimentalValues005);
createCSV('data/optimized.csv', getFunctionValues(optimized.b1, optimized.k));
createCSV('data/rnd.csv', checkRandomDistribution(), 'intrval, occurences');

/**
 * Вычислить вектор значений функции:
 * - если параметры не переданы, то теориетические значения, aka Y(теор.)
 * - если переданы параметры, модельные значения, aka Y(м.)
 *
 * всё верно говорю?
 *
 * @param  {Number} [b1] неизвестен по условию
 * @param  {Number} [k]  неизвестен по условию
 *
 * @return {[Number]}    вектор теоретических значений функции
 */
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

/**
 * Вычислить целевую функцию, aka CF (тип по заданию: 2)
 *
 * @param  {[Number]} experimentalValues вектор экспериментальных значений
 * @param  {[Number]} modelValues        вектор модельных значений
 *
 * @return {Number}                      значение целевой функции
 */
function getTargetFunction(experimentalValues, modelValues) {
  let targetValues = 0;
  for (let i = 0; i < modelValues.length; ++i) {
    targetValues += Math.pow(experimentalValues[i] - modelValues[i], 2);
  }

  return targetValues;
}

/**
 * Вычислить экспериментальные значения, aka Y(э)
 *
 * @param  {[Number]} theorValues вектор теоретических значений
 * @param  {Number}   factor      коэффициент зашумления
 *
 * @return {[Number]}             вектор экспериментальных значений
 */
function getExperimental(theorValues, factor) {
  const deltaY = Math.max.apply(null, theorValues) * factor;
  let experimentalValues = theorValues.slice();

  for (let i = 0; i < experimentalValues.length; ++i) {
    experimentalValues[i] += Math.random() * (2 * deltaY) - deltaY;
  }

  return experimentalValues;
}

/**
 * Проверка распределения случайных значений
 * @return {[Number]} вектор случайных значений по 10 группам
 */
function checkRandomDistribution() {
  const interval = 0.1;
  let randomNumber, distribution = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  for (var i = 0; i < 10000; ++i) {
    randomNumber = Math.random();
    ++distribution[Math.floor(randomNumber / interval)];
  }

  return distribution;
}

/**
 * Оптимизация методом Гаусса-Зейделя
 *
 * @param {[Number]} experimentalValues экспериментальные значения
 *
 * @return {object} объект двух пар ключ:значение
 */
function optimize(experimentalValues) {
  let
    // По условию неизвестны, берем из головы
    b1 = 2, k = 5,

    f = getTargetFunction(experimentalValues, getFunctionValues(b1, k)),
    f1,
    f2 = f,

    // Это, я так понимаю, шаги
    h1 = 0.1,
    h2 = 0.1,

    // А это вроде направление, то есть изменяемый параметр
    m = 1;

  while (true) {
    if (m == 1) {
      b1 = b1 + h1;
      f1 = getTargetFunction(experimentalValues, getFunctionValues(b1, k));

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
      f1 = getTargetFunction(experimentalValues, getFunctionValues(b1, k));

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
      return {b1, k};
    }

    f2 = f1;
  }
}

/**
 * Сохраняет CSV-файл
 *
 * @param  {String} filename  путь
 * @param  {[Any]}  data     массив значений
 * @param  {String} headers  заголовки таблицы
 *
 * @return {void}
 */
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
