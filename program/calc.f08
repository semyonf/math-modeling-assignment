program calc
    implicit none

    integer, parameter :: data_len = 25
    integer            :: i
    real               :: theor_values(data_len), experimental_values(data_len)

    call get_model(1.0, 4.0, theor_values)
    call get_experimental(theor_values, 0.02, experimental_values)

    write(*, '(i2, ",", f8.4)') (i, theor_values(i), i = 1, data_len)
    write(*, '(i2, ",", f8.4)') (i, experimental_values(i), i = 1, data_len)

contains

subroutine get_model(b1, k, output)
    real, intent(in)  :: b1, k
    real, intent(out) :: output(data_len)
    real, parameter   :: xt = 5, a = 3, b2 = 2
    real              :: z1 = 0, z2 = 0, z3 = 0, y = 0, h = 0.05

    do i = 1, data_len * 20
        z3 = (xt - z1 - (b1 + a) * z2 - (b1 + a * b1) * z3) / (a * b2)
        z2 = z2 + h * z3
        z1 = z1 + h * z2

        y = k * (z1 - a * z2)

        if (mod(i, 20) .eq. 0) output(i / 20) = y
    enddo
end subroutine get_model

subroutine get_experimental(theor, factor, experimental)
    real, intent(in)  :: theor(data_len), factor
    real, intent(out) :: experimental(data_len)
    real              :: deltaY

    deltaY = maxval(abs(theor)) * factor
    experimental = theor + (theor * rand() * (2 * deltaY) - deltaY)
end subroutine get_experimental

! subroutine optimize(func, startX, startY, optX, optY)
!     real, intent(in)  :: startX, startY
!     real, intent(out) :: optX, optY

! end subroutine optimize

end program calc
