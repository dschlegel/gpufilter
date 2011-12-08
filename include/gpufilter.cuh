/**
 *  @file gpufilter.cuh
 *  @brief CUDA device code for GPU-Efficient Recursive Filtering
 *  @author Rodolfo Lima
 *  @date September, 2011
 */

#ifndef GPUFILTER_CUH
#define GPUFILTER_CUH

//== NAMESPACES ===============================================================

namespace gpufilter {

//== PROTOTYPES ===============================================================

/**
 *  @ingroup gpu
 *  @brief Algorithm 4 stage 1
 *
 *  This function computes the algorithm stage 4.1 following:
 *
 *  \li In parallel for all \f$m\f$ and \f$n\f$, compute and store the
 *  \f$P_{m,n}(\bar{Y})\f$ and \f$E_{m,n}(\hat{Z})\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_in The input 2D image
 *  @param[out] g_transp_ybar All \f$P_{m,n}(\bar{Y})\f$
 *  @param[out] g_transp_zhat All \f$E_{m,n}(\hat{Z})\f$
 */
__global__
void alg4_stage1( const float *g_in,
                  float2 *g_transp_ybar,
                  float2 *g_transp_zhat );

/**
 *  @ingroup gpu
 *  @brief Algorithm 4 stage 2 and 3 (fusioned) or stage 5 and 6 (fusioned)
 *
 *  This function computes the algorithm stages 4.2 and 4.3 (also can
 *  be used to compute algorithm stages 4.5 and 4.6) following:
 *
 *  \li Sequentially for each \f$m\f$, but in parallel for each
 *  \f$n\f$, compute and store the \f$P_{m,n}(Y)\f$ and using the
 *  previously computed \f$P_{m,n}(\bar{Y})\f$.
 *
 *  \li Sequentially for each \f$m\f$, but in parallel for each
 *  \f$n\f$, compute and store the \f$E_{m,n}(Z)\f$ using the
 *  previously computed \f$P_{m-1,n}(Y)\f$ and \f$E_{m,n}(\hat{Z})\f$.
 *
 *  By considering g_transp_ybar as g_ubar and g_transp_zhat as g_vhat
 *  (cf. alg4_stage4() function), they can also be fixed to become g_u
 *  and g_v by using this function.  In this scenario, the function
 *  works exactly the same but follows:
 *
 *  \li Sequentially for each \f$n\f$, but in parallel for each
 *  \f$m\f$, compute and store the \f$P^T_{m,n}(U)\f$ from
 *  \f$P^T_{m,n}(\bar{U})\f$.
 *
 *  \li Sequentially for each \f$n\f$, but in parallel for each
 *  \f$m\f$, compute and store each \f$E^T_{m,n}(V)\f$ using the
 *  previously computed \f$P^T_{m,n-1}(U)\f$ and
 *  \f$E^T_{m,n}(\hat{V})\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_transp_ybar All \f$P_{m,n}(\bar{Y})\f$ fixed to \f$P_{m,n}(Y)\f$
 *  @param[in,out] g_transp_zhat All \f$E_{m,n}(\hat{Z})\f$ fixed to \f$E_{m,n}(Z)\f$
 */
__global__
void alg4_stage2_3_or_5_6( float2 *g_transp_ybar,
                           float2 *g_transp_zhat );

/**
 *  @ingroup gpu
 *  @brief Algorithm 4 stage 4
 *
 *  This function computes the algorithm stage 4.4 following:
 *
 *  \li In parallel for all \f$m\f$ and \f$n\f$, compute
 *  \f$B_{m,n}(Y)\f$ using the previously computed
 *  \f$P_{m-1,n}(Y)\f$. Then compute and store the \f$B_{m,n}(Z)\f$
 *  using the previously computed \f$E_{m+1,n}(Z)\f$.  Finally,
 *  compute and store both \f$P^T_{m,n}(\bar{U})\f$ and
 *  \f$E^T_{m,n}(\hat{V})\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_inout The input and output 2D image
 *  @param[in] g_transp_y All \f$P_{m,n}(Y)\f$
 *  @param[in] g_transp_z All \f$E_{m,n}(Z)\f$
 *  @param[out] g_ubar All \f$P^T_{m,n}(\bar{U})\f$
 *  @param[out] g_vhat All \f$E^T_{m,n}(\hat{V})\f$
 */
__global__
void alg4_stage4( float *g_inout,
                  const float2 *g_transp_y,
                  const float2 *g_transp_z,
                  float2 *g_ubar,
                  float2 *g_vhat );

/**
 *  @ingroup gpu
 *  @brief Algorithm 4 stage 7
 *
 *  This function computes the algorithm stage 4.7 following:
 *
 *  \li In parallel for all \f$m\f$ and \f$n\f$, compute
 *  \f$B_{m,n}(V)\f$ using the previously computed
 *  \f$P^T_{m,n-1}(V)\f$ and \f$B_{m,n}(Z)\f$.  Then compute and store
 *  the \f$B_{m,n}(U)\f$ using the previously computed
 *  \f$E_{m,n+1}(U)\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_inout The input and output 2D image
 *  @param[in] g_u All \f$P^T_{m,n}(U)\f$
 *  @param[in] g_v All \f$E^T_{m,n}(V)\f$
 */
__global__
void alg4_stage7( float *g_inout,
                  const float2 *g_u,
                  const float2 *g_v );

/**
 *  @ingroup gpu
 *  @brief Algorithm 5 stage 1
 *
 *  This function computes the algorithm stage 5.1 following:
 *
 *  \li In parallel for all \f$m\f$ and \f$n\f$, compute and store
 *  each \f$P_{m,n}(\bar{Y})\f$, \f$E_{m,n}(\hat{Z})\f$,
 *  \f$P^T_{m,n}(\check{U})\f$, and \f$E^T_{m,n}(\tilde{V})\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in] g_in The input 2D image
 *  @param[out] g_transp_pybar All \f$P_{m,n}(\bar{Y})\f$
 *  @param[out] g_transp_ezhat All \f$E_{m,n}(\hat{Z})\f$
 *  @param[out] g_ptucheck All \f$P^T_{m,n}(\check{U})\f$
 *  @param[out] g_etvtilde All \f$E^T_{m,n}(\tilde{V})\f$
 */
__global__
void alg5_stage1( const float *g_in,
                  float *g_transp_pybar,
                  float *g_transp_ezhat,
                  float *g_ptucheck,
                  float *g_etvtilde );

/**
 *  @ingroup gpu
 *  @brief Algorithm 5 stage 2 and 3 (fusioned)
 *
 *  This function computes the algorithm stages 5.2 and 5.3 following:
 *
 *  \li In parallel for all \f$n\f$, sequentially for each \f$m\f$,
 *  compute and store the \f$P_{m,n}(Y)\f$ and using the previously
 *  computed \f$P_{m,n}(\bar{Y})\f$.
 *
 *  with simple kernel fusioned (going thorough global memory):
 *
 *  \li In parallel for all \f$n\f$, sequentially for each \f$m\f$,
 *  compute and store \f$E_{m,n}(Z)\f$ using the previously computed
 *  \f$P_{m-1,n}(Y)\f$ and \f$E_{m+1,n}(\hat{Z})\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_transp_ybar All \f$P_{m,n}(\bar{Y})\f$ fixed to \f$P_{m,n}(Y)\f$
 *  @param[in,out] g_transp_zhat All \f$E_{m,n}(\hat{Z})\f$ fixed to \f$E_{m,n}(Z)\f$
 */
__global__
void alg5_stage2_3( float *g_transp_ybar,
                    float *g_transp_zhat );

/**
 *  @ingroup gpu
 *  @brief Algorithm 5 stage 4 and 5 (fusioned) step 1
 *
 *  This function computes the algorithm stages 5.4 and 5.5 following:
 *
 *  \li In parallel for all \f$m\f$, sequentially for each \f$n\f$,
 *  compute and store \f$P^T_{m,n}(U)\f$ and using the previously
 *  computed \f$P^T_{m,n}(\check{U})\f$, \f$P_{m-1,n}(Y)\f$, and
 *  \f$E_{m+1,n}(Z)\f$.
 *
 *  with simple kernel fusioned (going thorough global memory):
 *
 *  \li In parallel for all \f$m\f$, sequentially for each \f$n\f$,
 *  compute and store \f$E^T_{m,n}(V)\f$ and using the previously
 *  computed \f$E^T_{m,n}(\tilde{V})\f$, \f$P^T_{m,n-1}(U)\f$,
 *  \f$P_{m-1,n}(Y)\f$, and \f$E_{m+1,n}(Z)\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_ptucheck All \f$P^T_{m,n}(\check{U})\f$ fixed to \f$P^T_{m,n}(\bar{U})\f$
 *  @param[in,out] g_etvtilde All \f$E^T_{m,n}(\tilde{V})\f$ fixed to \f$E^T_{m,n}(\check{V})\f$
 *  @param[in] g_transp_py All \f$P_{m,n}(Y)\f$
 *  @param[in] g_transp_ez All \f$E_{m,n}(Z)\f$
 */
__global__
void alg5_stage4_5( float *g_ptucheck,
                    float *g_etvtilde,
                    const float *g_transp_py,
                    const float *g_transp_ez );

/**
 *  @ingroup gpu
 *  @brief Algorithm 5 stage 6
 *
 *  This function computes the algorithm stage 5.6 following:
 *
 *  \li In parallel for all \f$m\f$ and \f$n\f$, compute one after the
 *  other \f$B_{m,n}(Y)\f$, \f$B_{m,n}(Z)\f$, \f$B_{m,n}(U)\f$, and
 *  \f$B_{m,n}(V)\f$ and using the previously computed
 *  \f$P_{m-1,n}(Y)\f$, \f$E_{m+1,n}(Z)\f$, \f$P^T_{m,n-1}(U)\f$, and
 *  \f$E^T_{m,n+1}(V)\f$. Store \f$B_{m,n}(V)\f$.
 *
 *  @note The CUDA kernel functions (as this one) have many
 *  idiosyncrasies and should not be used lightly.
 *
 *  @see [Nehab:2011] cited in alg5()
 *  @param[in,out] g_inout The input and output 2D image
 *  @param[in] g_transp_py All \f$P_{m,n}(Y)\f$
 *  @param[in] g_transp_ez All \f$E_{m,n}(Z)\f$
 *  @param[in] g_ptu All \f$P^T_{m,n}(U)\f$
 *  @param[in] g_etv All \f$E^T_{m,n}(V)\f$
 */
__global__
void alg5_stage6( float *g_inout,
                  const float *g_transp_py,
                  const float *g_transp_ez,
                  const float *g_ptu,
                  const float *g_etv );

//=============================================================================
} // namespace gpufilter
//=============================================================================
#endif // GPUFILTER_CUH
//=============================================================================
