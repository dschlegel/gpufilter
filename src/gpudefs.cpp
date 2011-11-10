/**
 *  GPU definitions (implementation)
 *  @author Andre Maximo
 *  @author Rodolfo Lima
 *  @date March, 2011
 */

#include <vector>
#include <complex>

#include <symbol.h>

#include <gpudefs.cuh>

//== NAMESPACES ===============================================================

namespace gpufilter {

//== IMPLEMENTATION ===========================================================

void constants_sizes( dim3& g,
                      const int& h,
                      const int& w ) {

    g.x = (w+WS-1)/WS;
    g.y = (h+WS-1)/WS;

    copy_to_symbol("c_height", h);
	copy_to_symbol("c_width", w);
    copy_to_symbol("c_m_size", g.y);
	copy_to_symbol("c_n_size", g.x);

}

template <class T>

void mul(T R[2][2], const T A[2][2], const T B[2][2])
{
    T aux[2][2];
    aux[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0];
    aux[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1];

    aux[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0];
    aux[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1];

    R[0][0] = aux[0][0];
    R[0][1] = aux[0][1];
    R[1][0] = aux[1][0];
    R[1][1] = aux[1][1];
}


void calc_forward_matrix(float T[2][2], float n, float L, float M)
{
    if(n == 1)
    {
        T[0][0] = 0;
        T[0][1] = 1;
        T[1][0] = -L;
        T[1][1] = -M;
        return;
    }

    std::complex<float> delta = sqrt(std::complex<float>(M*M-4*L));

    std::complex<float> S[2][2] = {{1,1},
                     {-(delta+M)/2.f, (delta-M)/2.f}},
           iS[2][2] = {{(delta-M)/(2.f*delta), -1.f/delta},
                       {(delta+M)/(2.f*delta), 1.f/delta}};

    std::complex<float> LB[2][2] = {{-(delta+M)/2.f, 0},
                      {0,(delta-M)/2.f}};

    LB[0][0] = pow(LB[0][0], n);
    LB[1][1] = pow(LB[1][1], n);

    std::complex<float> cT[2][2];
    mul(cT, S, LB);
    mul(cT, cT, iS);

    T[0][0] = real(cT[0][0]);
    T[0][1] = real(cT[0][1]);
    T[1][0] = real(cT[1][0]);
    T[1][1] = real(cT[1][1]);
}


void calc_reverse_matrix(float T[2][2], float n, float L, float N)
{
    if(n == 1)
    {
        T[0][0] = -L*N;
        T[0][1] = -L;
        T[1][0] = 1;
        T[1][1] = 0;
        return;
    }

    std::complex<float> delta = sqrt(std::complex<float>(L*L*N*N)-4*L);

    std::complex<float> S[2][2] = {{1,1},
                                   {(delta-L*N)/(2*L), -(delta+L*N)/(2*L)}},
        iS[2][2] = {{(delta+L*N)/(2.f*delta), L/delta},
                    {(delta-L*N)/(2.f*delta), -L/delta}};
                        
    std::complex<float> LB[2][2] = {{-(delta+L*N)/2.f, 0},
                       {0, (delta-L*N)/2.f}};

    LB[0][0] = pow(LB[0][0], n);
    LB[1][1] = pow(LB[1][1], n);

    std::complex<float> cT[2][2];
    mul(cT, S, LB);
    mul(cT, cT, iS);

    T[0][0] = real(cT[0][0]);
    T[0][1] = real(cT[0][1]);
    T[1][0] = real(cT[1][0]);
    T[1][1] = real(cT[1][1]);
}


void calc_forward_reverse_matrix(float T[2][2], int n, float L, float M, float N)
{
    using std::swap;

    float block_raw[WS+4], *block = block_raw+2;

    block[-2] = 1;
    block[-1] = 0;

    block[n] = block[n+1] = 0;

    for(int i=0; i<2; ++i)
    {
        for(int j=0; j<n; ++j)
            block[j] = -L*block[j-2] - M*block[j-1];

        for(int j=n-1; j>=0; --j)
            block[j] = (block[j] - block[j+1]*N - block[j+2])*L;

        T[0][i] = block[0];
        T[1][i] = block[1];

        swap(block[-1], block[-2]); // [0, 1]
    }
}


void constants_coefficients1( const float& b0,
                              const float& a1 )
{
    const float Linf = a1, iR = b0*b0*b0*b0/Linf/Linf;

    std::vector<float> signrevprodLinf(WS);

    signrevprodLinf[WS-1] = 1;

    for(int i=WS-2; i>=0; --i)
        signrevprodLinf[i] = -signrevprodLinf[i+1]*Linf;

    copy_to_symbol("c_SignRevProdLinf", signrevprodLinf);

    std::vector<float> prodLinf(WS);

    prodLinf[0] = Linf;
    for(int i=1; i<WS; ++i)
        prodLinf[i] = prodLinf[i-1]*Linf;

    copy_to_symbol("c_ProdLinf", prodLinf);

    copy_to_symbol("c_iR1", iR);
    copy_to_symbol("c_Linf1", Linf);

    const float Linf2 = Linf*Linf,
                alpha = Linf2*(1-pow(Linf2,WS))/(1-Linf2),
                stm = (WS & 1 ? -1 : 1)*pow(Linf, WS);

    copy_to_symbol("c_Stm", stm);
    copy_to_symbol("c_Svm", stm);
    copy_to_symbol("c_Alpha", alpha);

    std::vector<float> delta_x_tail(WS), delta_y(WS);

    delta_x_tail[WS-1] = -Linf;
    for(int j=WS-2; j>=0; --j)
        delta_x_tail[j] = -delta_x_tail[j+1]*Linf;

    float sign = WS & 1 ? -1 : 1;
    for(int j=WS-1; j>=0; --j)
    {
        delta_y[j] = sign*pow(Linf,2+j)*(1-pow(Linf,2*(WS+1-j)))/(1-Linf*Linf);
        sign *= -1;
    }

    copy_to_symbol("c_Delta_x_tail", delta_x_tail);
    copy_to_symbol("c_Delta_y", delta_y);
}


void constants_coefficients2( const float& b0,
                              const float& a1,
                              const float& a2 )
{
    const float Linf = a2, Ninf = a1/a2, Minf = a1, iR = b0*b0*b0*b0/Linf/Linf;

    copy_to_symbol("c_iR2", iR);
    copy_to_symbol("c_Linf2", Linf);
    copy_to_symbol("c_Minf", Minf);
    copy_to_symbol("c_Ninf", Ninf);

    copy_to_symbol("c_Llast2", Linf);

    float T[2][2];
    calc_forward_matrix(T, WS, Linf, Minf);
    copy_to_symbol("c_Af",std::vector<float>(&T[0][0], &T[0][0]+4));

    calc_reverse_matrix(T, WS, Linf, Ninf);
    copy_to_symbol("c_Ar",std::vector<float>(&T[0][0], &T[0][0]+4));

    calc_forward_reverse_matrix(T, WS, Linf, Minf, Ninf);
    copy_to_symbol("c_Arf",std::vector<float>(&T[0][0], &T[0][0]+4));
}

//=============================================================================
} // namespace gpufilter
//=============================================================================