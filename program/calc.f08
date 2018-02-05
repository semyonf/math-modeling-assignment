program calc
    implicit none

    integer, parameter :: data_len = 25
    integer            :: i
    real(8)            :: Y_theor(data_len), Y_E1(data_len), Y_E2(data_len), Y_E3(data_len)
    real(8)            :: RANDOM(data_len), optim_x, optim_y

    do i = 1, data_len
        RANDOM(i) = rand()
    enddo

    call get_model(1.0_8, 4.0_8, Y_theor)
    call get_experimental(Y_theor, 5e-2_8, Y_E1)
    call get_experimental(Y_theor, 1e-1_8, Y_E2)
    call get_experimental(Y_theor, 2e-1_8, Y_E3)

    write(*, '(i2, ",", f8.4)') (i, Y_theor(i), i = 1, data_len)
    write(*, '(i2, ",", f8.4)') (i, Y_E1(i), i = 1, data_len)

    call optimize(2.0_8, 5.0_8, optim_x, optim_y, Y_E1)

    write(*,*) optim_x, optim_y
contains

! точно работает !
pure subroutine get_model(b1, k, result)
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
end subroutine get_model

! точно работает !
pure subroutine get_experimental(M, factor, E)
    real(8), intent(in)  :: M(data_len), factor
    real(8), intent(out) :: E(data_len)
    real(8)              :: delta_y

    delta_y = maxval(abs(M)) * factor

    E = M + (RANDOM * (2 * delta_y) - delta_y)
end subroutine get_experimental

! работает !
pure real(8) function calculate_cf(b1, k, E)
    real(8), intent(in) :: b1, k, E(data_len)
    real(8)             :: M(data_len)

    call get_model(b1 ,k, M)

    calculate_cf = sum((E - M) ** 2)
end function calculate_cf

pure subroutine optimize(start_x, start_y, optimal_x, optimal_y, Y_E1)
    real(8), intent(in)  :: start_x, start_y, Y_E1(data_len)
    real(8), intent(out) :: optimal_x, optimal_y
    real(8)              :: x, y, f, f1, f2, delta_x, delta_y
    integer              :: m

    x = start_x
    y = start_y

    f = calculate_cf(x, y, Y_E1)
    f2 = f

    delta_x = 0.1_8
    delta_y = 0.1_8

    m = 1

    do
        if (m == 1) then
            x = x + delta_x
            f1 = calculate_cf(x, y, Y_E1)

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
            f1 = calculate_cf(x, y, Y_E1)

            if (f1 <= f) then
                delta_y = delta_y * 3.0_8
                f = f1
            else
                y = y - delta_y
                delta_y = delta_y * (-0.5_8)
            endif

            m = 1
        endif

        if (abs(f2 - f1) < 1e-5_8) then
            optimal_x = x
            optimal_y = y

            exit
        endif

        f2 = f1
    enddo
end subroutine optimize

end program calc
