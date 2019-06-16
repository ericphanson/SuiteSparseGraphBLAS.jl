var documenterSearchIndex = {"docs":
[{"location":"matrix_methods/#Basic-matrix-functions-1","page":"Basic matrix functions","title":"Basic matrix functions","text":"","category":"section"},{"location":"matrix_methods/#","page":"Basic matrix functions","title":"Basic matrix functions","text":"Modules = [SuiteSparseGraphBLAS]\nPages   = [\n    \"Object_Methods/Matrix_Methods.jl\",\n]\nPrivate = false","category":"page"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_build-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Matrix{T},Array{U,1},Array{U,1},Array{T,1},U,GrB_BinaryOp}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_build","text":"GrB_Matrix_build(C, I, J, X, nvals, dup)\n\nStore elements from tuples into a matrix.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> @GxB_Matrix_fprint(MAT, GxB_COMPLETE)\n\nGraphBLAS matrix: MAT\nnrows: 4 ncols: 4 max # entries: 5\nformat: standard CSR vlen: 4 nvec_nonempty: 3 nvec: 4 plen: 4 vdim: 4\nhyper_ratio 0.0625\nGraphBLAS type:  int8_t size: 1\nnumber of entries: 5\nrow: 1 : 1 entries [0:0]\n    column 1: int8 2\nrow: 2 : 3 entries [1:3]\n    column 1: int8 4\n    column 2: int8 3\n    column 3: int8 5\nrow: 3 : 1 entries [4:4]\n    column 3: int8 6\n\n\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_clear-Tuple{GrB_Matrix}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_clear","text":"GrB_Matrix_clear(A)\n\nRemove all elements from a matrix.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_nvals(MAT)\n5\n\njulia> GrB_Matrix_clear(MAT)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_nvals(MAT)\n0\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_dup-Union{Tuple{T}, Tuple{GrB_Matrix{T},GrB_Matrix{T}}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_dup","text":"GrB_Matrix_dup(C, A)\n\nCreate a new matrix with the same domain, dimensions, and contents as another matrix.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> B = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_dup(B, MAT)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> @GxB_Matrix_fprint(B, GxB_SHORT)\n\nGraphBLAS matrix: B\nnrows: 4 ncols: 4 max # entries: 5\nformat: standard CSR vlen: 4 nvec_nonempty: 3 nvec: 4 plen: 4 vdim: 4\nhyper_ratio 0.0625\nGraphBLAS type:  int8_t size: 1\nnumber of entries: 5\nrow: 1 : 1 entries [0:0]\n    column 1: int8 2\nrow: 2 : 3 entries [1:3]\n    column 1: int8 4\n    column 2: int8 3\n    column 3: int8 5\nrow: 3 : 1 entries [4:4]\n    column 3: int8 6\n\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_extractElement-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Matrix{T},U,U}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_extractElement","text":"GrB_Matrix_extractElement(A, row_index, col_index)\n\nReturn element of a matrix at a given index (A[rowindex][colindex]) if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_extractElement(MAT, 1, 1)\n2\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_extractTuples-Union{Tuple{GrB_Matrix{T}}, Tuple{T}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_extractTuples","text":"GrB_Matrix_extractTuples(A)\n\nReturn tuples stored in a matrix.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_extractTuples(MAT)\n([1, 2, 2, 2, 3], [1, 1, 2, 3, 3], Int8[2, 4, 3, 5, 6])\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_ncols-Tuple{GrB_Matrix}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_ncols","text":"GrB_Matrix_ncols(A)\n\nReturn the number of columns in a matrix if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_ncols(MAT)\n4\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_new-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Matrix{T},GrB_Type{T},U,U}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_new","text":"GrB_Matrix_new(A, type, nrows, ncols)\n\nCreate a new matrix with specified domain and dimensions.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_nrows-Tuple{GrB_Matrix}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_nrows","text":"GrB_Matrix_nrows(A)\n\nReturn the number of rows in a matrix if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_nrows(MAT)\n4\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_nvals-Tuple{GrB_Matrix}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_nvals","text":"GrB_Matrix_nvals(A)\n\nReturn the number of stored elements in a matrix if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_nvals(MAT)\n5\n\n\n\n\n\n","category":"method"},{"location":"matrix_methods/#SuiteSparseGraphBLAS.GrB_Matrix_setElement-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Matrix{T},T,U,U}} where T<:Union{Bool, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic matrix functions","title":"SuiteSparseGraphBLAS.GrB_Matrix_setElement","text":"GrB_Matrix_setElement(C, X, I, J)\n\nSet one element of a matrix to a given value, C[I][J] = X.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> MAT = GrB_Matrix{Int8}()\nGrB_Matrix{Int8}\n\njulia> GrB_Matrix_new(MAT, GrB_INT8, 4, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 2, 2, 3]; J = [1, 2, 1, 3, 3]; X = Int8[2, 3, 4, 5, 6]; n = 5;\n\n\njulia> GrB_Matrix_build(MAT, I, J, X, n, GrB_FIRST_INT8)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_extractElement(MAT, 1, 1)\n2\n\njulia> GrB_Matrix_setElement(MAT, Int8(7), 1, 1)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Matrix_extractElement(MAT, 1, 1)\n7\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#Basic-vector-functions-1","page":"Basic vector functions","title":"Basic vector functions","text":"","category":"section"},{"location":"vector_methods/#","page":"Basic vector functions","title":"Basic vector functions","text":"Modules = [SuiteSparseGraphBLAS]\nPages   = [\n    \"Object_Methods/Vector_Methods.jl\",\n]\nPrivate = false","category":"page"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_build-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Vector{T},Array{U,1},Array{T,1},U,GrB_BinaryOp}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_build","text":"GrB_Vector_build(w, I, X, nvals, dup)\n\nStore elements from tuples into a vector.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> @GxB_Vector_fprint(V, GxB_SHORT)\n\nGraphBLAS vector: V\nnrows: 4 ncols: 1 max # entries: 3\nformat: standard CSC vlen: 4 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1\nhyper_ratio 0.0625\nGraphBLAS type:  double size: 8\nnumber of entries: 3\ncolumn: 0 : 3 entries [0:2]\n    row 0: double 2.1\n    row 2: double 3.2\n    row 3: double 4.4\n\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_clear-Tuple{GrB_Vector}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_clear","text":"GrB_Vector_clear(v)\n\nRemove all the elements (tuples) from a vector.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Int64}()\nGrB_Vector{Int64}\n\njulia> GrB_Vector_new(V, GrB_INT64, 5)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 4]; X = [2, 32, 4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractTuples(V)\n([1, 2, 4], [2, 32, 4])\n\njulia> GrB_Vector_clear(V)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractTuples(V)\n(Int64[], Int64[])\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_dup-Union{Tuple{T}, Tuple{GrB_Vector{T},GrB_Vector{T}}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_dup","text":"GrB_Vector_dup(w, u)\n\nCreate a new vector with the same domain, size, and contents as another vector.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Int64}()\nGrB_Vector{Int64}\n\njulia> GrB_Vector_new(V, GrB_INT64, 5)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 4]; X = [2, 32, 4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> B = GrB_Vector{Int64}()\nGrB_Vector{Int64}\n\njulia> GrB_Vector_dup(B, V)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> @GxB_Vector_fprint(B, GxB_SHORT)\n\nGraphBLAS vector: B\nnrows: 5 ncols: 1 max # entries: 3\nformat: standard CSC vlen: 5 nvec_nonempty: 1 nvec: 1 plen: 1 vdim: 1\nhyper_ratio 0.0625\nGraphBLAS type:  int64_t size: 8\nnumber of entries: 3\ncolumn: 0 : 3 entries [0:2]\n    row 1: int64 2\n    row 2: int64 32\n    row 4: int64 4\n\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_extractElement-Union{Tuple{U}, Tuple{T}, Tuple{GrB_Vector{T},U}} where U<:Union{Int64, UInt64} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_extractElement","text":"GrB_Vector_extractElement(v, i)\n\nReturn element of a vector at a given index (v[i]) if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractElement(V, 2)\n3.2\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_extractTuples-Union{Tuple{GrB_Vector{T}}, Tuple{T}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_extractTuples","text":"GrB_Vector_extractTuples(v)\n\nReturn tuples stored in a vector.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractTuples(V)\n([0, 2, 3], [2.1, 3.2, 4.4])\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_new-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Vector{T},GrB_Type{T},U}} where T<:Union{Bool, Float32, Float64, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_new","text":"GrB_Vector_new(v, type, n)\n\nCreate a new vector with specified domain and size.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_nvals-Tuple{GrB_Vector}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_nvals","text":"GrB_Vector_nvals(v)\n\nReturn the number of stored elements in a vector if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_nvals(V)\n3\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_setElement-Union{Tuple{T}, Tuple{U}, Tuple{GrB_Vector{T},T,U}} where T<:Union{Bool, Int16, Int32, Int64, Int8, UInt16, UInt32, UInt64, UInt8} where U<:Union{Int64, UInt64}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_setElement","text":"GrB_Vector_setElement(w, x, i)\n\nSet one element of a vector to a given value, w[i] = x.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Int64}()\nGrB_Vector{Int64}\n\njulia> GrB_Vector_new(V, GrB_INT64, 5)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [1, 2, 4]; X = [2, 32, 4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_INT64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractElement(V, 2)\n32\n\njulia> GrB_Vector_setElement(V, 7, 2)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_extractElement(V, 2)\n7\n\n\n\n\n\n","category":"method"},{"location":"vector_methods/#SuiteSparseGraphBLAS.GrB_Vector_size-Tuple{GrB_Vector}","page":"Basic vector functions","title":"SuiteSparseGraphBLAS.GrB_Vector_size","text":"GrB_Vector_size(v)\n\nReturn the size of a vector if successful. Else return value of type GrB Info.\n\nExamples\n\njulia> using SuiteSparseGraphBLAS\n\njulia> GrB_init(GrB_NONBLOCKING)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> V = GrB_Vector{Float64}()\nGrB_Vector{Float64}\n\njulia> GrB_Vector_new(V, GrB_FP64, 4)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> I = [0, 2, 3]; X = [2.1, 3.2, 4.4]; n = 3;\n\njulia> GrB_Vector_build(V, I, X, n, GrB_FIRST_FP64)\nGrB_SUCCESS::GrB_Info = 0\n\njulia> GrB_Vector_size(V)\n4\n\n\n\n\n\n","category":"method"}]
}
