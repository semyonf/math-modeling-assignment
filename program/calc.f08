program calc
    implicit none

    character(*), parameter :: E_ = "UTF-8"
    integer :: Out
    integer, parameter :: data_len = 25
    real(8), parameter :: b1_act = 1.0, k_act = 4.0, b1_fake = 2.0, k_fake = 5.0

    integer :: i
    real(8) :: RANDOM(data_len), Y_theor(data_len), Y_exp(3, data_len), optim_b1(3), optim_k(3)

    do i = 1, data_len
        RANDOM(i) = rand()
    enddo

    call calc_model(b1_act, k_act, Y_theor)
    call calc_experimental(Y_theor, Y_exp)

    open (file="dat/theor.csv", encoding=E_, newunit=Out)
        write(Out, '("x, y")')
        write(Out, '(i2, ",", f8.4)') (i, Y_theor(i), i = 1, data_len)
    close (Out)

    open (file="dat/exp1.csv", encoding=E_, newunit=Out)
        write(Out, '("x, y")')
        write(Out, '(i2, ",", f8.4)') (i, Y_exp(1, i), i = 1, data_len)
    close (Out)

    open (file="dat/exp2.csv", encoding=E_, newunit=Out)
        write(Out, '("x, y")')
        write(Out, '(i2, ",", f8.4)') (i, Y_exp(2, i), i = 1, data_len)
    close (Out)

    open (file="dat/exp3.csv", encoding=E_, newunit=Out)
        write(Out, '("x, y")')
        write(Out, '(i2, ",", f8.4)') (i, Y_exp(3, i), i = 1, data_len)
    close (Out)

    ! write(*, '(i2, ",", f8.4)') (i, Y_exp(1,i), i = 1, data_len)

    do concurrent (i=1:3)
        call optimize(b1_fake, k_fake, optim_b1(i), optim_k(i), Y_exp(i,:))
    enddo

    ! write(*, '("CF", i1, ":  ", "b1=", f6.4,"  k=", f6.4)') (i, optim_b1(i), optim_k(i), i = 1, 3)
    ! write(*,*) sum(optim_b1) / 3, sum(optim_k) / 3

contains

pure subroutine calc_model(b1, k, result)
    real(8), intent(in)  :: b1, k
    real(8), intent(out) :: result(data_len)
    real(8), parameter   :: xt = 5, a = 3, b2 = 2
    real(8)              :: z1, z2, z3, y, h
    integer              :: i

    z1 = 0
    z2 = 0
    z3 = 0
    y = 0
    h = 0.05

    do i = 1, data_len * 20
        z3 = (xt - z1 - (b1 + a) * z2 - (b1 + a * b1) * z3) / (a * b2)
        z2 = z2 + h * z3
        z1 = z1 + h * z2

        y = k * (z1 - a * z2)

        if (mod(i, 20) .eq. 0) result(i / 20) = y
    enddo
end subroutine calc_model

pure subroutine calc_experimental(M, E)
    real(8), intent(in)  :: M(data_len)
    real(8), intent(out) :: E(3, data_len)
    real(8)              :: delta_y, factors(3)
    integer              :: i

    factors = (/0.05, 0.1, 0.2/)

    do concurrent (i=1:3)
        delta_y = maxval(abs(M)) * factors(i)
        E(i,:) = M + (RANDOM * (2 * delta_y) - delta_y)
    enddo
end subroutine calc_experimental

pure real(8) function calculate_cf(b1, k, E)
    real(8), intent(in) :: b1, k, E(data_len)
    real(8)             :: M(data_len)

    call calc_model(b1 ,k, M)
    calculate_cf = sum((E - M) ** 2)
end function calculate_cf

pure subroutine optimize(start_x, start_y, optimal_x, optimal_y, Y_exp)
    real(8), intent(in)  :: start_x, start_y, Y_exp(data_len)
    real(8), intent(out) :: optimal_x, optimal_y
    real(8)              :: x, y, f, f1, f2, delta_x, delta_y
    integer              :: m

    x = start_x
    y = start_y

    f = calculate_cf(x, y, Y_exp)
    f2 = f

    delta_x = 0.1_8
    delta_y = 0.1_8

    m = 1

    do
        if (m == 1) then
            x = x + delta_x
            f1 = calculate_cf(x, y, Y_exp)

            if (f1 <= f) then
                delta_x = delta_x * 3.0_8
                f = f1
            else
                x = x - delta_x
                delta_x = delta_x * (-0.5_8)
            endif

            m = m + 1
        else if (m /= 1) then
            y = y + delta_y
            f1 = calculate_cf(x, y, Y_exp)

            if (f1 <= f) then
                delta_y = delta_y * 3.0_8
                f = f1
            else
                y = y - delta_y
                delta_y = delta_y * (-0.5_8)
            endif

            m = 1
        endif

        if (abs(f2 - f1) < 1e-1_8) then
            optimal_x = x
            optimal_y = y

            exit
        endif

        f2 = f1
    enddo
end subroutine optimize

end program calc
