! Моделирование процесса параметрической идентификации динамического объекта
! (вариант 39).
!
!   W(s) = k(1 - as) / ((1 + as)(1 + b1 s + b2 s^2)),  x(t) = 5 (ступенька)
!
! Неизвестные параметры: k, b1. Метод оптимизации: GZ1. Целевая функция:
! CF = sum (Y_э - Y_м)^2. Шум: равномерный на (-dy; dy), dy = max|Y_т| * {5, 10, 20}%.
!
! Все числа и таблицы, которые попадают в отчёт, программа пишет в каталог data/,
! в том числе файл data/results.tex с LaTeX-макросами.
module identification
    use, intrinsic :: iso_fortran_env, only: dp => real64
    implicit none
    private
    public :: run

    abstract interface
        real(dp) function objective(x, y)
            import :: dp
            real(dp), intent(in) :: x, y
        end function objective
    end interface

    ! Параметры объекта
    real(dp), parameter :: xt = 5, a = 3, b2 = 2
    real(dp), parameter :: b1_act = 1, k_act = 4       ! истинные значения неизвестных
    real(dp), parameter :: b1_start = 2, k_start = 5   ! начальная точка оптимизации

    ! Интегрирование методом Эйлера и наблюдение выхода
    real(dp), parameter :: h = 0.01_dp                 ! шаг интегрирования
    integer,  parameter :: steps_per_point = 100       ! шагов между наблюдениями (dt = 1)
    integer,  parameter :: data_len = 25               ! число наблюдений, t = 1..25

    ! Шум
    real(dp), parameter :: noise_levels(3) = [0.05_dp, 0.1_dp, 0.2_dp]
    ! Веса опытов обратно пропорциональны дисперсии шума: w ~ 1 / dy^2
    real(dp), parameter :: weights(3) = (1 / noise_levels**2) / sum(1 / noise_levels**2)

    ! Оптимизация GZ1
    real(dp), parameter :: opt_step = 0.1_dp           ! начальный шаг по каждой координате
    real(dp), parameter :: opt_eps = 1e-6_dp           ! останов: все шаги меньше eps
    integer,  parameter :: opt_max_cycles = 100000

    ! Проверка ГСЧ и статистика оценок
    integer,  parameter :: rng_samples = 10000, rng_bins = 10
    integer,  parameter :: mc_runs = 200               ! повторений опыта (Монте-Карло)

    character(*), parameter :: E_ = "UTF-8"

    ! Состояние расчёта, общее для процедур модуля
    integer  :: Out, iters(3)
    real(dp) :: Y_theor(data_len), Y_exp(3, data_len), cf_data(data_len)
    real(dp) :: dy(3), est_b1(3), est_k(3), cf_min(3)
    real(dp) :: b1_mean, k_mean, b1_wmean, k_wmean

contains

subroutine run()
    integer               :: i, j, n_seed
    integer, allocatable  :: seed(:)
    real(dp)              :: Y_final(data_len), max_dev, t
    character(len=64)     :: path

    ! Фиксированное зерно: результаты воспроизводимы от сборки к сборке
    call random_seed(size=n_seed)
    allocate(seed(n_seed))
    seed = [(20171230 + 7919 * i, i = 1, n_seed)]
    call random_seed(put=seed)

    open (file="data/results.tex", encoding=E_, newunit=Out)
    write(Out, '(a)') "% Файл сгенерирован program/calc.f08, не редактировать вручную"

    ! ---------------------------------------------------------------- Часть 1
    call calc_model(b1_act, k_act, Y_theor)

    max_dev = 0
    do i = 1, data_len
        max_dev = max(max_dev, abs(Y_theor(i) - exact_response(b1_act, k_act, real(i, dp))))
    enddo

    call write_table("data/theor.csv", Y_theor, with_exact=.true.)

    block
        integer :: u
        open (file="data/exact.csv", encoding=E_, newunit=u)
            write(u, '(a)') "t, y"
            do i = 0, 10 * data_len
                t = i / 10.0_dp
                write(u, '(f5.1, ",", f9.4)') t, exact_response(b1_act, k_act, t)
            enddo
        close (u)
    end block

    ! Самопроверка: численное решение должно совпадать с точным
    if (max_dev > 0.5_dp) error stop "Euler solution deviates from the exact step response"

    call put_macro("StepH", h, 2)
    call put_macro("EulerMaxDev", max_dev, 3)
    call put_macro("YTheorMax", maxval(abs(Y_theor)), 3)
    call put_macro("YTheorLast", Y_theor(data_len), 3)

    ! ---------------------------------------------------------------- Часть 2
    call run_test(ellipse, 4.0_dp, 3.0_dp, 0.0_dp, 0.0_dp, "data/opt-ellipse.csv", "Ellipse")
    call run_test(rosenbrock, -1.2_dp, 1.0_dp, 1.0_dp, 1.0_dp, "data/opt-rosenbrock.csv", "Rosenbrock")

    ! ---------------------------------------------------------------- Часть 3
    call check_rng()

    dy = maxval(abs(Y_theor)) * noise_levels
    call put_macro("DyA", dy(1), 3)
    call put_macro("DyB", dy(2), 3)
    call put_macro("DyC", dy(3), 3)

    do j = 1, 3
        call add_noise(Y_theor, dy(j), Y_exp(j, :))
        write(path, '("data/exp", i1, ".csv")') j
        call write_table(trim(path), Y_exp(j, :), with_exact=.false.)
    enddo

    ! ---------------------------------------------------------------- Часть 4
    do j = 1, 3
        cf_data = Y_exp(j, :)
        write(path, '("data/opt-cf", i1, ".csv")') j
        call optimize(target_function, b1_start, k_start, est_b1(j), est_k(j), cf_min(j), &
                      iters(j), trim(path))
    enddo

    b1_mean = sum(est_b1) / 3
    k_mean = sum(est_k) / 3
    b1_wmean = sum(weights * est_b1)
    k_wmean = sum(weights * est_k)

    call calc_model(b1_wmean, k_wmean, Y_final)
    call write_table("data/final.csv", Y_final, with_exact=.false.)

    call write_results_table()
    call monte_carlo()

    close (Out)

    write(*, '("Euler vs exact: max |dy| = ", f7.4)') max_dev
    write(*, '("CF", i1, ":  b1=", f7.4, "  k=", f7.4, "  CF=", f9.3, "  cycles=", i0)') &
        (j, est_b1(j), est_k(j), cf_min(j), iters(j), j = 1, 3)
    write(*, '("mean:      b1=", f7.4, "  k=", f7.4)') b1_mean, k_mean
    write(*, '("weighted:  b1=", f7.4, "  k=", f7.4)') b1_wmean, k_wmean
end subroutine run

! Решение системы
!   z1' = z2,  z2' = z3,  z3' = (x - z1 - (a + b1) z2 - (b2 + a b1) z3) / (a b2),
!   y = k (z1 - a z2)
! явным методом Эйлера при нулевых начальных условиях. В result(n) записывается
! значение y в момент t = n.
pure subroutine calc_model(b1, k, result)
    real(dp), intent(in)  :: b1, k
    real(dp), intent(out) :: result(data_len)
    real(dp)              :: z1, z2, z3, dz3
    integer               :: n, step

    z1 = 0
    z2 = 0
    z3 = 0

    do n = 1, data_len
        do step = 1, steps_per_point
            dz3 = (xt - z1 - (a + b1) * z2 - (b2 + a * b1) * z3) / (a * b2)

            z1 = z1 + h * z2
            z2 = z2 + h * z3
            z3 = z3 + h * dz3
        enddo

        result(n) = k * (z1 - a * z2)
    enddo
end subroutine calc_model

! Точная переходная характеристика (для проверки метода Эйлера):
!   y(t) = x * (W(0) + sum_p  P(p) e^{pt} / (p Q'(p))),
! где p -- простые корни Q(s) = (1 + as)(1 + b1 s + b2 s^2).
pure real(dp) function exact_response(b1, k, t)
    real(dp), intent(in) :: b1, k, t
    complex(dp)          :: p(3), acc, disc
    real(dp)             :: q1, q2, q3
    integer              :: j

    q3 = a * b2
    q2 = b2 + a * b1
    q1 = a + b1

    disc = sqrt(cmplx(b1**2 - 4 * b2, 0, dp))
    p(1) = cmplx(-1 / a, 0, dp)
    p(2) = (-b1 + disc) / (2 * b2)
    p(3) = (-b1 - disc) / (2 * b2)

    acc = k
    do j = 1, 3
        acc = acc + k * (1 - a * p(j)) * exp(p(j) * t) / (p(j) * (3 * q3 * p(j)**2 + 2 * q2 * p(j) + q1))
    enddo

    exact_response = xt * real(acc, dp)
end function exact_response

! Y_э = Y_т + СЧ, СЧ равномерно распределено на (-dy; dy)
subroutine add_noise(M, dy, E)
    real(dp), intent(in)  :: M(data_len), dy
    real(dp), intent(out) :: E(data_len)
    real(dp)              :: r(data_len)

    call random_number(r)
    E = M + (2 * r - 1) * dy
end subroutine add_noise

! Целевая функция 2: CF = sum (Y_э - Y_м)^2, Y_э берётся из cf_data
real(dp) function target_function(b1, k)
    real(dp), intent(in) :: b1, k
    real(dp)             :: M(data_len)

    call calc_model(b1, k, M)
    target_function = sum((cf_data - M)**2)
end function target_function

real(dp) function ellipse(x, y)
    real(dp), intent(in) :: x, y

    ! эллиптический параболоид, оси повёрнуты на 45 градусов, отношение полуосей 1:3
    ellipse = 5 * x**2 + 8 * x * y + 5 * y**2
end function ellipse

real(dp) function rosenbrock(x, y)
    real(dp), intent(in) :: x, y

    rosenbrock = (1 - x)**2 + 100 * (y - x**2)**2
end function rosenbrock

! Метод GZ1: поочерёдные пробные шаги по координатам; при удаче шаг
! утраивается, при неудаче шаг отменяется, уменьшается вдвое и меняет знак.
! Останов -- когда шаги по всем координатам стали меньше opt_eps.
subroutine optimize(f, start_x, start_y, optimal_x, optimal_y, f_min, cycles, path)
    procedure(objective)                 :: f
    real(dp), intent(in)                 :: start_x, start_y
    real(dp), intent(out)                :: optimal_x, optimal_y, f_min
    integer,  intent(out)                :: cycles
    character(*), intent(in), optional   :: path
    real(dp)                             :: x, y, fx, f1, delta_x, delta_y
    integer                              :: u

    x = start_x
    y = start_y
    fx = f(x, y)
    delta_x = opt_step
    delta_y = opt_step

    if (present(path)) then
        open (file=path, encoding=E_, newunit=u)
        write(u, '(a)') "cycle, x, y"
        write(u, '(i0, ",", es22.14, ",", es22.14)') 0, x, y
    endif

    do cycles = 1, opt_max_cycles
        x = x + delta_x
        f1 = f(x, y)
        if (f1 <= fx) then
            fx = f1
            delta_x = 3 * delta_x
        else
            x = x - delta_x
            delta_x = -0.5_dp * delta_x
        endif

        y = y + delta_y
        f1 = f(x, y)
        if (f1 <= fx) then
            fx = f1
            delta_y = 3 * delta_y
        else
            y = y - delta_y
            delta_y = -0.5_dp * delta_y
        endif

        ! длинные траектории прореживаются, чтобы графики оставались лёгкими
        if (present(path)) then
            if (cycles <= 200 .or. mod(cycles, 20) == 0) &
                write(u, '(i0, ",", es22.14, ",", es22.14)') cycles, x, y
        endif

        if (max(abs(delta_x), abs(delta_y)) < opt_eps) exit
    enddo

    if (cycles > opt_max_cycles) then
        cycles = opt_max_cycles
        write(*, '("warning: GZ1 reached ", i0, " cycles without convergence")') cycles
    endif

    if (present(path)) then
        write(u, '(i0, ",", es22.14, ",", es22.14)') cycles, x, y
        close (u)
    endif

    optimal_x = x
    optimal_y = y
    f_min = fx
end subroutine optimize

! Проверка оптимизатора на функции с известным минимумом (x_min; y_min)
subroutine run_test(f, x0, y0, x_min, y_min, path, name)
    procedure(objective) :: f
    real(dp), intent(in) :: x0, y0, x_min, y_min
    character(*), intent(in) :: path, name
    real(dp)                 :: x_opt, y_opt, f_opt

    call optimize(f, x0, y0, x_opt, y_opt, f_opt, iters(1), path)
    if (hypot(x_opt - x_min, y_opt - y_min) > 1e-2_dp) then
        write(*, '("GZ1 failed on test function ", a)') name
        error stop 1
    endif

    ! координаты около нуля печатаются в экспоненциальной форме
    call put_macro(name // "X", x_opt, merge(2, 5, abs(x_opt) < 1e-2_dp), sci=abs(x_opt) < 1e-2_dp)
    call put_macro(name // "Y", y_opt, merge(2, 5, abs(y_opt) < 1e-2_dp), sci=abs(y_opt) < 1e-2_dp)
    call put_macro(name // "F", f_opt, 2, sci=.true.)
    call put_macro(name // "Cycles", real(iters(1), dp), 0)
end subroutine run_test

! Гистограмма rng_samples значений ГСЧ на [0; 1) и критерий хи-квадрат
subroutine check_rng()
    real(dp), allocatable :: r(:)
    real(dp)              :: expected, chi2
    integer               :: counts(rng_bins), u, i, j

    allocate(r(rng_samples))
    call random_number(r)
    counts = 0
    do i = 1, rng_samples
        j = min(int(r(i) * rng_bins) + 1, rng_bins)
        counts(j) = counts(j) + 1
    enddo

    expected = real(rng_samples, dp) / rng_bins
    chi2 = sum((counts - expected)**2 / expected)

    open (file="data/rng-hist.csv", encoding=E_, newunit=u)
        write(u, '(a)') "bin, count"
        write(u, '(f4.2, ",", i0)') ((i - 0.5_dp) / rng_bins, counts(i), i = 1, rng_bins)
    close (u)

    call put_macro("RngMean", sum(r) / rng_samples, 4)
    call put_macro("RngVar", sum((r - sum(r) / rng_samples)**2) / (rng_samples - 1), 4)
    call put_macro("RngChiSq", chi2, 2)
    call put_macro("RngSamples", real(rng_samples, dp), 0)
end subroutine check_rng

subroutine write_results_table()
    character(*), parameter :: row = '(a, " & ", a, " & ", a, " & ", a, " & ", a, " & ", a, " \\ \hline")'
    character(len=32) :: name
    integer           :: j

    write(Out, '(a)') "\newcommand{\ResultsRows}{"
    do j = 1, 3
        write(name, '("$CF_", i1, "$ (", i0, "\%)")') j, nint(noise_levels(j) * 100)
        write(Out, row) trim(name), num(est_k(j), 4), rel(est_k(j), k_act), &
            num(est_b1(j), 4), rel(est_b1(j), b1_act), num(cf_min(j), 2)
    enddo
    write(Out, row) "среднее", num(k_mean, 4), rel(k_mean, k_act), &
        num(b1_mean, 4), rel(b1_mean, b1_act), "--"
    write(Out, row) "взвешенное среднее", num(k_wmean, 4), rel(k_wmean, k_act), &
        num(b1_wmean, 4), rel(b1_wmean, b1_act), "--"
    write(Out, '(a)') "}"

    call put_macro("WeightA", weights(1), 3)
    call put_macro("WeightB", weights(2), 3)
    call put_macro("WeightC", weights(3), 3)
    call put_macro("KFinal", k_wmean, 4)
    call put_macro("BFinal", b1_wmean, 4)
end subroutine write_results_table

! Повторение опыта mc_runs раз с новыми реализациями шума: среднее и
! СКО оценок для каждого уровня шума и для двух способов объединения опытов
subroutine monte_carlo()
    real(dp) :: b1s(mc_runs, 5), ks(mc_runs, 5), Y_noisy(data_len), f_min, mean_b1, mean_k
    integer  :: r, c, j, cycles
    character(len=64) :: label(5)

    label(1) = "5\%"
    label(2) = "10\%"
    label(3) = "20\%"
    label(4) = "среднее"
    label(5) = "взвешенное среднее"

    do r = 1, mc_runs
        do j = 1, 3
            call add_noise(Y_theor, dy(j), Y_noisy)
            cf_data = Y_noisy
            call optimize(target_function, b1_start, k_start, b1s(r, j), ks(r, j), f_min, cycles)
        enddo
        b1s(r, 4) = sum(b1s(r, 1:3)) / 3
        ks(r, 4) = sum(ks(r, 1:3)) / 3
        b1s(r, 5) = sum(weights * b1s(r, 1:3))
        ks(r, 5) = sum(weights * ks(r, 1:3))
    enddo

    write(Out, '(a)') "\newcommand{\MonteCarloRows}{"
    do c = 1, 5
        mean_k = sum(ks(:, c)) / mc_runs
        mean_b1 = sum(b1s(:, c)) / mc_runs
        write(Out, '(a, " & ", a, " & ", a, " & ", a, " & ", a, " \\ \hline")') trim(label(c)), &
            num(mean_k, 3), num(sqrt(sum((ks(:, c) - mean_k)**2) / (mc_runs - 1)), 3), &
            num(mean_b1, 3), num(sqrt(sum((b1s(:, c) - mean_b1)**2) / (mc_runs - 1)), 3)
    enddo
    write(Out, '(a)') "}"
    call put_macro("MonteCarloRuns", real(mc_runs, dp), 0)
end subroutine monte_carlo

subroutine write_table(path, Y, with_exact)
    character(*), intent(in) :: path
    real(dp), intent(in)     :: Y(data_len)
    logical, intent(in)      :: with_exact
    integer                  :: u, i

    open (file=path, encoding=E_, newunit=u)
        if (with_exact) then
            write(u, '(a)') "t, y, exact"
            write(u, '(i2, ",", f9.4, ",", f9.4)') &
                (i, Y(i), exact_response(b1_act, k_act, real(i, dp)), i = 1, data_len)
        else
            write(u, '(a)') "t, y"
            write(u, '(i2, ",", f9.4)') (i, Y(i), i = 1, data_len)
        endif
    close (u)
end subroutine write_table

subroutine put_macro(name, value, digits, sci)
    character(*), intent(in)      :: name
    real(dp), intent(in)          :: value
    integer, intent(in)           :: digits
    logical, intent(in), optional :: sci
    character(len=40)             :: buf
    integer                       :: e

    if (present(sci)) then
        if (sci .and. abs(value) > tiny(value)) then
            e = floor(log10(abs(value)))
            buf = num(value / 10.0_dp**e, digits)
            write(Out, '("\newcommand{\", a, "}{", a, " \cdot 10^{", i0, "}}")') name, trim(buf), e
            return
        endif
    endif
    write(Out, '("\newcommand{\", a, "}{", a, "}")') name, num(value, digits)
end subroutine put_macro

! Число с заданным количеством знаков после точки, без пробелов
function num(value, digits) result(s)
    real(dp), intent(in)          :: value
    integer, intent(in)           :: digits
    character(len=:), allocatable :: s
    character(len=40)             :: buf, fmt

    if (digits == 0) then
        write(buf, '(i0)') nint(value)
    else
        write(fmt, '("(f40.", i0, ")")') digits
        write(buf, fmt) value
    endif
    s = trim(adjustl(buf))
end function num

! Относительная погрешность оценки в процентах
function rel(estimate, actual) result(s)
    real(dp), intent(in)          :: estimate, actual
    character(len=:), allocatable :: s

    s = num(100 * abs(estimate - actual) / abs(actual), 1) // "\%"
end function rel

end module identification

program calc
    use identification, only: run
    implicit none

    call run()
end program calc
