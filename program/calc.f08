program calc
    implicit none

    integer, parameter :: data_len = 25
    real :: theor_values(data_len)

    call get_model(1.0, 4.0, theor_values)

    write(*, *) theor_values

contains

subroutine get_model(b1, k, output)
    real, intent(in)  :: b1, k
    real, intent(out) :: output(data_len)
    real, parameter   :: xt = 5, a = 3, b2 = 2
    real              :: y = 0, z1 = 0, z2 = 0, z3 = 0, h = 0.05
    integer           :: i

    do i = 1, data_len * 20
        z3 = (xt - z1 - (b1 + a) * z2 - (b1 + a * b1) * z3) / (a * b2)
        z2 = z2 + h * z3
        z1 = z1 + h * z2

        y = k * (z1 - a * z2)

        if (mod(i, 20) .eq. 0) output(i / 20) = y
    enddo
end subroutine get_model

end program calc
