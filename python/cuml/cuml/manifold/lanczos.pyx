#
# Copyright (c) 2024-2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# distutils: language = c++

from cuml.internals.safe_imports import cpu_only_import
np = cpu_only_import('numpy')
pd = cpu_only_import('pandas')
from cuml.internals.safe_imports import gpu_only_import
cupy = gpu_only_import('cupy')

from pylibraft.common.handle cimport handle_t
from pylibraft.common.handle import Handle

from cuml.internals.array import CumlArray

from cuml.common import input_to_cuml_array

rmm = gpu_only_import('rmm')


from libc.stdint cimport uintptr_t
from libc.stdint cimport uint64_t

cimport cuml.common.cuda


cdef extern from "cuml/solvers/lanczos.hpp" namespace "ML::Solver":

    cdef void lanczos_solver(
        const handle_t& handle,
        int* rows,
        int* cols,
        double* vals,
        int nnz,
        int n,
        int n_components,
        int max_iterations,
        int ncv,
        double tolerance,
        uint64_t seed,
        double* v0,
        double* eigenvalues,
        double* eigenvectors,
    ) except +

    cdef void lanczos_solver(
        const handle_t& handle,
        int* rows,
        int* cols,
        float* vals,
        int nnz,
        int n,
        int n_components,
        int max_iterations,
        int ncv,
        float tolerance,
        uint64_t seed,
        float* v0,
        float* eigenvalues,
        float* eigenvectors,
    ) except +

    cdef void old_lanczos_solver(
        const handle_t& handle,
        int* rows,
        int* cols,
        double* vals,
        int nnz,
        int n,
        int n_components,
        int max_iterations,
        int ncv,
        double tolerance,
        uint64_t seed,
        double* v0,
        double* eigenvalues,
        double* eigenvectors,
    ) except +

    cdef void old_lanczos_solver(
        const handle_t& handle,
        int* rows,
        int* cols,
        float* vals,
        int nnz,
        int n,
        int n_components,
        int max_iterations,
        int ncv,
        float tolerance,
        uint64_t seed,
        float* v0,
        float* eigenvalues,
        float* eigenvectors,
    ) except +


# @cuml.internals.api_return_array(get_output_type=True)
def eig_lanczos(A, n_components, seed, dtype, maxiter=4000, tol=0.01, conv_n_iters = 5, conv_eps = 0.001, restartiter=15, v0=None, handle=Handle()):

    # rows = CumlArrayDescriptor()
    # cols = CumlArrayDescriptor()
    # vals = CumlArrayDescriptor()

    # Acoo = A.tocoo()
    # rows = Acoo.row
    # cols = Acoo.col
    # vals = Acoo.data

    rows = A.indptr
    cols = A.indices
    vals = A.data

    rows, n, p, _ = \
        input_to_cuml_array(rows, order='C', check_dtype=np.int32,
                            convert_to_dtype=(np.int32))

    cols, n, p, _ = \
        input_to_cuml_array(cols, order='C', check_dtype=np.int32,
                            convert_to_dtype=(np.int32))

    vals, n, p, _ = \
        input_to_cuml_array(vals, order='C', check_dtype=dtype,
                            convert_to_dtype=(dtype))

    N = A.shape[0]

    eigenvectors = CumlArray.zeros(
                    (N, n_components),
                    order="F",
                    dtype=dtype)

    eigenvalues = CumlArray.zeros(
                    (n_components),
                    order="F",
                    dtype=dtype)

    if v0 is None:
        rng = np.random.default_rng(seed)
        v0 = rng.random((N,)).astype(dtype)

    v0, n, p, _ = \
        input_to_cuml_array(v0, order='C', check_dtype=dtype,
                            convert_to_dtype=(dtype))

    # v0print = v0.to_output(output_type="numpy")
    # print("v0", np.array2string(v0print, separator=', '))

    cdef int eig_iters = 0
    # cdef int* eig_iters_ptr = &eig_iters

    cdef uintptr_t eigenvectors_ptr = eigenvectors.ptr
    cdef uintptr_t eigenvalues_ptr = eigenvalues.ptr
    cdef uintptr_t rows_ptr = rows.ptr
    cdef uintptr_t cols_ptr = cols.ptr
    cdef uintptr_t vals_ptr = vals.ptr
    cdef uintptr_t v0_ptr = v0.ptr

    handle = Handle() if handle is None else handle
    cdef handle_t *handle_ = <handle_t*> <size_t> handle.getHandle()

    if dtype == np.float32:
        lanczos_solver(
            handle_[0],
            <int*> rows_ptr,
            <int*> cols_ptr,
            <float*> vals_ptr,
            <int> A.nnz,
            <int> N,
            <int> n_components,
            <int> maxiter,
            <int> restartiter,
            <float> tol,
            <long long> seed,
            <float*> v0_ptr,
            <float*> eigenvalues_ptr,
            <float*> eigenvectors_ptr,
        )
    elif dtype == np.float64:
        lanczos_solver(
            handle_[0],
            <int*> rows_ptr,
            <int*> cols_ptr,
            <double*> vals_ptr,
            <int> A.nnz,
            <int> N,
            <int> n_components,
            <int> maxiter,
            <int> restartiter,
            <double> tol,
            <long long> seed,
            <double*> v0_ptr,
            <double*> eigenvalues_ptr,
            <double*> eigenvectors_ptr,
        )

    return cupy.asnumpy(eigenvalues), cupy.asnumpy(eigenvectors), eig_iters


def old_eig_lanczos(A, n_components, seed, dtype, maxiter=4000, tol=0.01, conv_n_iters = 5, conv_eps = 0.001, restartiter=15, v0=None, handle=Handle()):

    # rows = CumlArrayDescriptor()
    # cols = CumlArrayDescriptor()
    # vals = CumlArrayDescriptor()

    # Acoo = A.tocoo()
    # rows = Acoo.row
    # cols = Acoo.col
    # vals = Acoo.data

    rows = A.indptr
    cols = A.indices
    vals = A.data

    rows, n, p, _ = \
        input_to_cuml_array(rows, order='C', check_dtype=np.int32,
                            convert_to_dtype=(np.int32))

    cols, n, p, _ = \
        input_to_cuml_array(cols, order='C', check_dtype=np.int32,
                            convert_to_dtype=(np.int32))

    vals, n, p, _ = \
        input_to_cuml_array(vals, order='C', check_dtype=dtype,
                            convert_to_dtype=(dtype))

    N = A.shape[0]

    eigenvectors = CumlArray.zeros(
                    (N, n_components),
                    order="F",
                    dtype=dtype)

    eigenvalues = CumlArray.zeros(
                    (n_components),
                    order="F",
                    dtype=dtype)

    if v0 is None:
        rng = np.random.default_rng(seed)
        v0 = rng.random((N,)).astype(dtype)

    v0, n, p, _ = \
        input_to_cuml_array(v0, order='C', check_dtype=dtype,
                            convert_to_dtype=(dtype))

    # v0print = v0.to_output(output_type="numpy")
    # print("v0", np.array2string(v0print, separator=', '))

    cdef int eig_iters = 0
    # cdef int* eig_iters_ptr = &eig_iters

    cdef uintptr_t eigenvectors_ptr = eigenvectors.ptr
    cdef uintptr_t eigenvalues_ptr = eigenvalues.ptr
    cdef uintptr_t rows_ptr = rows.ptr
    cdef uintptr_t cols_ptr = cols.ptr
    cdef uintptr_t vals_ptr = vals.ptr
    cdef uintptr_t v0_ptr = v0.ptr

    handle = Handle() if handle is None else handle
    cdef handle_t *handle_ = <handle_t*> <size_t> handle.getHandle()

    if dtype == np.float32:
        old_lanczos_solver(
            handle_[0],
            <int*> rows_ptr,
            <int*> cols_ptr,
            <float*> vals_ptr,
            <int> A.nnz,
            <int> N,
            <int> n_components,
            <int> maxiter,
            <int> restartiter,
            <float> tol,
            <long long> seed,
            <float*> v0_ptr,
            <float*> eigenvalues_ptr,
            <float*> eigenvectors_ptr,
        )
    elif dtype == np.float64:
        old_lanczos_solver(
            handle_[0],
            <int*> rows_ptr,
            <int*> cols_ptr,
            <double*> vals_ptr,
            <int> A.nnz,
            <int> N,
            <int> n_components,
            <int> maxiter,
            <int> restartiter,
            <double> tol,
            <long long> seed,
            <double*> v0_ptr,
            <double*> eigenvalues_ptr,
            <double*> eigenvectors_ptr,
        )

    return cupy.asnumpy(eigenvalues), cupy.asnumpy(eigenvectors), eig_iters
