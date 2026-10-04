## Моделирование процесса параметрической идентификации динамического объекта (вариант 39)

Курсовая работа по дисциплине «Математические модели» (СПбПУ, 2017).

### Сборка

```sh
make        # собрать программу, посчитать данные (data/) и отчёт (out/report.pdf)
make calc   # только расчёт
```

Нужны `gfortran` и `pdflatex` (пакеты `texlive-latex-extra`, `texlive-lang-cyrillic`,
`texlive-science`, `texlive-pictures`). Все числа, таблицы и графики в отчёте программа
`program/calc.f08` генерирует при сборке: CSV-файлы и макросы в `data/results.tex`.
Зерно ГСЧ фиксировано, поэтому результаты воспроизводимы.

### Исправления (2026)

Исходная версия содержала ошибку, из-за которой моделировался не тот объект:

- **Метод Эйлера.** В `calc_model` производной $\dot z_3$ присваивалась сама переменная
  (`z3 = (...)/(a*b2)` вместо `z3 = z3 + h*(...)/(a*b2)`). Фактически решалось уравнение
  второго порядка $11\ddot u + 4\dot u + u = x$ вместо заданного
  $6\dddot u + 5\ddot u + 4\dot u + u = x$. Ошибка доходила до 7.3 (около 35 % от
  установившегося значения). Проверка через предел её не обнаруживала: у обеих систем
  предел равен 20. Шум и подгонка строились по той же неверной модели, поэтому
  идентификация «сходилась».
- Добавлена проверка по точной переходной характеристике (через вычеты); программа
  завершается с ошибкой, если решение Эйлера с ней расходится. Шаг уменьшен до
  h = 0.01 (отклонение ≈ 0.1).
- **Критерий останова GZ1.** Раньше сравнивались два соседних пробных значения функции:
  поиск мог остановиться далеко от минимума, а при исчерпании итераций результат
  оставался неопределённым. Теперь останов происходит, когда все шаги меньше 1e-6.
- Тестовые функции (повёрнутый эллипс, Розенброк из (−1.2; 1)) считаются той же программой.
  Раньше их траектории были получены другим кодом, а у траектории Розенброка
  в CSV были потеряны минусы.
- Проверка ГСЧ: гистограмма самого используемого генератора, выборочные моменты, критерий χ².
- Оценки параметров дополнены относительными погрешностями, взвешенным по точности опытов
  средним и статистикой по 200 повторениям опыта (Монте-Карло).
- В отчёт добавлены введение и список источников, выводы приведены в соответствие с работой.

> Оформление не полностью соответствует ГОСТ для научной работы

> Copyright (c) 2018 Semyon Fomin
>
> Permission is hereby granted, free of charge, to any person obtaining
> a copy of this software and associated documentation files (the
> "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish,
> distribute, sublicense, and/or sell copies of the Software, and to
> permit persons to whom the Software is furnished to do so, subject to
> the following conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
> EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
> IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
> CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
> TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
> SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>
