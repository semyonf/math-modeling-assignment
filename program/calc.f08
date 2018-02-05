program calc
    implicit none

    integer, parameter :: data_len = 25
    integer            :: i
    real               :: model_values(data_len), experimental_values(data_len)
    real               :: RANDOM(data_len)

    do i = 1, data_len
        RANDOM(i) = rand()
    enddo

    call get_model(1.5, 7.0, model_values)
    call get_experimental(model_values, 0.05, experimental_values)

    write(*, '(i2, ",", f15.4)') (i, model_values(i), i = 1, data_len)
    write(*, '(i2, ",", f15.4)') (i, experimental_values(i), i = 1, data_len)

    ! write(*, '(f18.4)') sum((experimental_values - model_values) **2)

    ! call optimize(1.5, 7.0, optimized_x, optimized_y)

    ! write(*,*) optimized_x, optimized_y
contains

! точно работает !
pure subroutine get_model(b1, k, result)
    real, intent(in)  :: b1, k
    real, intent(out) :: result(data_len)
    real, parameter   :: xt = 5, a = 3, b2 = 2
    real              :: z1, z2, z3, y, h
    integer           :: i

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

! работает !
pure subroutine get_experimental(M, factor, E)
    real, intent(in)  :: M(data_len), factor
    real, intent(out) :: E(data_len)
    real              :: delta_y

    delta_y = maxval(abs(M)) * factor

    E = M + (RANDOM * (2 * delta_y) - delta_y)
end subroutine get_experimental

! работает !
pure real function calculate_cf(b1, k)
    real, intent(in) :: b1, k
    real             :: M(data_len), E(data_len)

    call get_model(b1 ,k, M)
    call get_experimental(M, 0.05, E)

    calculate_cf = sum((E - M) ** 2)
end function calculate_cf

! pure subroutine optimize(start_x, start_y, optimal_x, optimal_y)
!     real, intent(in)  :: start_x, start_y
!     real, intent(out) :: optimal_x, optimal_y
!     real              :: x, y, f, f1, f2, delta_x, delta_y, m

!     x = start_x
!     y = start_y

!     f = calculate_cf(x, y)
!     f2 = f

!     delta_x = 0.1
!     delta_y = 0.1

!     m = 1

!     do
!         if (m .eq. 1) then
!             x = x + delta_x
!             f1 = calculate_cf(x, y)

!             if (f1 .le. f) then
!                 delta_x = delta_x * 3
!                 f = f1
!             else
!                 x = x - delta_x
!                 delta_x = delta_x * (-0.5)
!             endif

!             m = m + 1
!         else if (m .ne. 1) then
!             y = y + delta_y
!             f1 = calculate_cf(x, y)

!             if (f1 .le. f) then
!                 delta_y = delta_y * 3
!                 f = f1
!             else
!                 y = y - delta_y
!                 delta_y = delta_y * (-0.5)
!             endif

!             m = 1
!         endif

!         if (abs(f2 - f1) .le. 1e-5) then
!             optimal_x = x
!             optimal_y = y

!             exit
!         else
!             ! write(*,*) x, y, f1
!         endif

!         f2 = f1
!     enddo
! end subroutine optimize

end program calc
