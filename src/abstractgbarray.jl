# AbstractGBArray functions:

Base.unsafe_convert(::Type{LibGraphBLAS.GrB_Matrix}, A::AbstractGBArray) = A.p[]
Base.unsafe_convert(::Type{LibGraphBLAS.GrB_Vector}, A::AbstractGBVector) = LibGraphBLAS.GrB_Vector(A.p[])

_newGrBRef() = finalizer(Ref{LibGraphBLAS.GrB_Matrix}()) do ref
    @wraperror LibGraphBLAS.GrB_Matrix_free(ref)
end
function _copyGrBMat(r::Base.RefValue{LibGraphBLAS.GrB_Matrix})
    C = Ref{LibGraphBLAS.GrB_Matrix}()
    LibGraphBLAS.GrB_Matrix_dup(C, r[])
    return C
end

_canbeoutput(A::AbstractGBArray) = true

function SparseArrays.nnz(A::GBArrayOrTranspose)
    nvals = Ref{LibGraphBLAS.GrB_Index}()
    @wraperror LibGraphBLAS.GrB_Matrix_nvals(nvals, parent(A))
    return Int64(nvals[])
end

Base.eltype(::Type{GBArrayOrTranspose{T}}) where{T} = T

"""
    empty!(A::AbstractGBArray)

Clear all the entries from the GBArray.
Does not modify the type or dimensions.
"""
function Base.empty!(A::GBArrayOrTranspose)
    @wraperror LibGraphBLAS.GrB_Matrix_clear(parent(A))
    return A
end

function Base.copyto!(C::AbstractGBArray, A::GBArrayOrTranspose)
    if C isa AbstractVector
        C[:] = A
    else
        C[:, :] = A
    end
    return C
end

function Base.Matrix(A::GBArrayOrTranspose)
    T = copy(A) # We copy here to 1. avoid densifying A, and 2. to avoid destroying A.
    return unpack!(T, Dense())
end

function Base.Vector(A::GBVectorOrTranspose)
    format = sparsitystatus(A)
    if format === Dense()
        T = unpack!(A, Dense(); attachfinalizer = false)
        M = copy(T)
        pack!(A, T, false)
    else
        # if A is not dense we end up doing 2x copies. Once to avoid densifying A.
        T = copy(A)
        U = unpack!(T, Dense(); attachfinalizer = false)
        # And again to make this a native Julia Array.
        # if we didn't copy here a user could not resize
        M = copy(U)
        pack!(T, U, false)
    end
    M
end

function SparseArrays.SparseMatrixCSC(A::GBArrayOrTranspose)
    T = copy(A) # avoid changing sparsity of A and destroying it.
    return unpack!(T, SparseMatrixCSC)
end

function SparseArrays.SparseVector(v::GBVectorOrTranspose)
    T = copy(v) # avoid changing sparsity of v and destroying it.
    return unpack!(T, SparseVector)
end

# AbstractGBMatrix functions:
#############################

function reshape!(
    A::AbstractGBMatrix, nrows, ncols; 
    bycol::Bool = true, desc = nothing
)
    desc = _handledescriptor(desc)
    lenA = length(A)
    nrows isa Colon && ncols isa Colon && throw(
        ArgumentError("nrows and ncols may not both be Colon"))
    nrows isa Colon && (nrows = lenA ÷ ncols)
    ncols isa Colon && (ncols = lenA ÷ nrows)
    @wraperror LibGraphBLAS.GxB_Matrix_reshape(
        A, bycol, nrows, ncols, desc
    )
    return A
end
reshape!(A::AbstractGBMatrix, dims...; bycol = true) = 
    reshape!(A, dims...; bycol)
reshape!(A::AbstractGBMatrix, n; bycol = true) =
    reshape!(A, n, 1; bycol)
function Base.reshape(
    A::AbstractGBMatrix, nrows, ncols; 
    bycol = true, desc = nothing)
    desc = _handledescriptor(desc)
    lenA = length(A)
    nrows isa Colon && ncols isa Colon && throw(
        ArgumentError("nrows and ncols may not both be Colon"))
    nrows isa Colon && (nrows = lenA ÷ ncols)
    ncols isa Colon && (ncols = lenA ÷ nrows)
    C = Ref{LibGraphBLAS.GrB_Matrix}()
    @wraperror LibGraphBLAS.GxB_Matrix_reshapeDup(
        C, A, 
        bycol, nrows, ncols, desc
    )
    # TODO, do better. This is ugly and allocates twice.
    out = similar(A)
    out.p = finalizer(C) do ref
        @wraperror LibGraphBLAS.GrB_Matrix_free(ref)
    end
    return out
end
Base.reshape(A::AbstractGBMatrix, dims::Tuple{Vararg{Int64, N}}; bycol = true) where N =
    reshape(A, dims...; bycol)
Base.reshape(A::AbstractGBMatrix, dims::Tuple{Vararg{Union{Colon, Int64}}}; bycol = true) =
    reshape(A, dims...; bycol)
Base.reshape(
    A::AbstractGBMatrix, 
    dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}};
    bycol = true
) = reshape(A, dims...; bycol)

Base.reshape(A::AbstractGBMatrix, n; bycol = true) = reshape(A, n, 1; bycol)

function build!(A::AbstractGBMatrix{T}, I::AbstractVector, J::AbstractVector, x::T) where {T}
    nnz(A) == 0 || throw(OutputNotEmptyError("Cannot build matrix with existing elements"))
    length(I) == length(J) || DimensionMismatch("I, J and X must have the same length")
    x = GBScalar(x)

    @wraperror LibGraphBLAS.GxB_Matrix_build_Scalar(
        A,
        Vector{LibGraphBLAS.GrB_Index}(decrement!(I)),
        Vector{LibGraphBLAS.GrB_Index}(decrement!(J)),
        x,
        length(I)
    )
    increment!(I)
    increment!(J)
    return A
end

function Base.size(A::AbstractGBMatrix)
    nrows = Ref{LibGraphBLAS.GrB_Index}()
    ncols = Ref{LibGraphBLAS.GrB_Index}()
    @wraperror LibGraphBLAS.GrB_Matrix_nrows(nrows, A)
    @wraperror LibGraphBLAS.GrB_Matrix_ncols(ncols, A)
    return (Int64(nrows[]), Int64(ncols[]))
end

function Base.deleteat!(A::AbstractGBMatrix, i, j)
    @wraperror LibGraphBLAS.GrB_Matrix_removeElement(A, decrement!(i), decrement!(j))
    return A
end

function Base.resize!(A::AbstractGBMatrix, nrows_new, ncols_new)
    @wraperror LibGraphBLAS.GrB_Matrix_resize(A, nrows_new, ncols_new)
    return A
end

# Type dependent functions build, setindex, getindex, and findnz:
for T ∈ valid_vec
    if T ∈ gxb_vec
        prefix = :GxB
    else
        prefix = :GrB
    end
    # Build functions
    func = Symbol(prefix, :_Matrix_build_, suffix(T))
    @eval begin
        function build!(A::AbstractGBMatrix{$T}, I::AbstractVector{<:Integer}, J::AbstractVector{<:Integer}, X::AbstractVector{$T};
                combine = +
            )
            _canbeoutput(A) || throw(ShallowException())
            combine = binaryop(combine, $T)
            I isa Vector || (I = collect(I))
            J isa Vector || (J = collect(J))
            X isa Vector || (X = collect(X))
            nnz(A) == 0 || throw(OutputNotEmptyError("Cannot build matrix with existing elements"))
            length(X) == length(I) == length(J) ||
                DimensionMismatch("I, J and X must have the same length")
            decrement!(I)
            decrement!(J)
            @wraperror LibGraphBLAS.$func(
                A,
                I,
                J,
                X,
                length(X),
                combine
            )
            increment!(I)
            increment!(J)
        end
    end
    # Setindex functions
    func = Symbol(prefix, :_Matrix_setElement_, suffix(T))
    @eval begin
        function Base.setindex!(A::AbstractGBMatrix{$T}, x, i::Integer, j::Integer)
            x = convert($T, x)
            @wraperror LibGraphBLAS.$func(A, x, LibGraphBLAS.GrB_Index(decrement!(i)), LibGraphBLAS.GrB_Index(decrement!(j)))
            return x
        end
    end
    # Getindex functions
    func = Symbol(prefix, :_Matrix_extractElement_, suffix(T))
    @eval begin
        function Base.getindex(A::AbstractGBMatrix{$T}, i::Integer, j::Integer)
            x = Ref{$T}()
            result = LibGraphBLAS.$func(x, A, decrement!(i), decrement!(j))
            if result == LibGraphBLAS.GrB_SUCCESS
                return x[]
            elseif result == LibGraphBLAS.GrB_NO_VALUE
                return A.fill
            else
                @wraperror result
            end
        end
        # Fix ambiguity
        function Base.getindex(A::Transpose{$T, <:AbstractGBMatrix{$T}}, i::Int, j::Int)
            return getindex(parent(A), j, i)
        end
    end
    # findnz functions
    func = Symbol(prefix, :_Matrix_extractTuples_, suffix(T))
    @eval begin
        function SparseArrays.findnz(A::AbstractGBMatrix{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            J = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            X = Vector{$T}(undef, nvals[])
            wait(A)
            @wraperror LibGraphBLAS.$func(I, J, X, nvals, A)
            nvals[] == length(I) == length(J) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
            return increment!(I), increment!(J), X
        end
        function SparseArrays.nonzeros(A::AbstractGBMatrix{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
            X = Vector{$T}(undef, nvals[])
            wait(A)
            @wraperror LibGraphBLAS.$func(C_NULL, C_NULL, X, nvals, A)
            nvals[] == length(X) || throw(DimensionMismatch(""))
            return X
        end
        function SparseArrays.nonzeroinds(A::AbstractGBMatrix{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            J = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            wait(A)
            @wraperror LibGraphBLAS.$func(I, J, C_NULL, nvals, A)
            nvals[] == length(I) == length(J) || throw(DimensionMismatch(""))
            return increment!(I), increment!(J)
        end
    end
end

function build!(
        A::AbstractGBMatrix{T}, I::AbstractVector{<:Integer}, J::AbstractVector{<:Integer}, X::AbstractVector{T};
        combine = +
    ) where {T}
    _canbeoutput(A) || throw(ShallowException())
    combine = binaryop(combine, T)
    I isa Vector || (I = collect(I))
    J isa Vector || (J = collect(J))
    X isa Vector || (X = collect(X))
    nnz(A) == 0 || throw(OutputNotEmptyError("Cannot build matrix with existing elements"))
    length(X) == length(I) == length(J) ||
        DimensionMismatch("I, J and X must have the same length")
    decrement!(I)
    decrement!(J)
    @wraperror LibGraphBLAS.GrB_Matrix_build_UDT(
        A,
        I,
        J,
        X,
        length(X),
        combine
    )
    increment!(I)
    increment!(J)
end

function Base.setindex!(A::AbstractGBMatrix{T}, x, i::Integer, j::Integer) where {T}
    x = convert(T, x)
    in = Ref{T}(x)
    @wraperror LibGraphBLAS.GrB_Matrix_setElement_UDT(A, in, LibGraphBLAS.GrB_Index(decrement!(i)), LibGraphBLAS.GrB_Index(decrement!(j)))
    return x
end

function Base.getindex(A::AbstractGBMatrix{T}, i::Integer, j::Integer) where {T}
    x = Ref{T}()
    result = LibGraphBLAS.GrB_Matrix_extractElement_UDT(x, A, decrement!(i), decrement!(j))
    if result == LibGraphBLAS.GrB_SUCCESS
        return x[]
    elseif result == LibGraphBLAS.GrB_NO_VALUE
        return A.fill
    else
        @wraperror result
    end
end
# Fix ambiguity
function Base.getindex(A::Transpose{T, <:AbstractGBMatrix{T}}, i::Integer, j::Integer) where {T}
    return getindex(parent(A), j, i)
end

# findnz functions for UDTs
function SparseArrays.findnz(A::AbstractGBMatrix{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
    I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    J = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    X = Vector{T}(undef, nvals[])
    wait(A)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(I, J, X, nvals, A)
    nvals[] == length(I) == length(J) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
    return increment!(I), increment!(J), X
end
function SparseArrays.nonzeros(A::AbstractGBMatrix{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
    X = Vector{T}(undef, nvals[])
    wait(A)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(C_NULL, C_NULL, X, nvals, A)
    nvals[] == length(X) || throw(DimensionMismatch(""))
    return X
end
function SparseArrays.nonzeroinds(A::AbstractGBMatrix{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
    I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    J = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    wait(A)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(I, J, C_NULL, nvals, A)
    nvals[] == length(I) == length(J) || throw(DimensionMismatch(""))
    return increment!(I), increment!(J)
end

for T ∈ valid_vec
    func = Symbol(:GxB_Matrix_subassign_, suffix(T))
    @eval begin
        function _subassign(C::AbstractGBMatrix{$T}, x::$T, I, ni, J, nj, mask, accum, desc)
            @wraperror LibGraphBLAS.$func(C, mask, accum, x, I, ni, J, nj, desc)
            return x
        end
    end
    if T ∈ gxb_vec
        prefix = :GxB
    else
        prefix = :GrB
    end
    func = Symbol(prefix, :_Matrix_assign_, suffix(T))
    @eval begin
        function _assign(C::AbstractGBMatrix{$T}, x, I, ni, J, nj, mask, accum, desc)
            @wraperror LibGraphBLAS.$func(C, mask, accum, x, I, ni, J, nj, desc)
            return x
        end
    end
end

function Base.isstored(A::AbstractGBMatrix, i::Int, j::Int)
    result = LibGraphBLAS.GxB_Matrix_isStoredElement(A, decrement!(i), decrement!(j))
    if result == LibGraphBLAS.GrB_SUCCESS
        true
    elseif result == LibGraphBLAS.GrB_NO_VALUE
        false
    else
        @wraperror result
    end
end

# type dependent functions for UDTs
function _subassign(C::AbstractGBMatrix{T}, x::T, I, ni, J, nj, mask, accum, desc) where {T}
    in = Ref{T}(x)
    @wraperror LibGraphBLAS.GxB_Matrix_subassign_UDT(C, mask, accum, in, I, ni, J, nj, desc)
    return x
end
function _assign(C::AbstractGBMatrix{T}, x::T, I, ni, J, nj, mask, accum, desc) where {T}
    in = Ref{T}(x)
    @wraperror LibGraphBLAS.GrB_Matrix_assign_UDT(C, mask, accum, in, I, ni, J, nj, desc)
    return x
end

# subassign fallback for Matrix <- Matrix, and Matrix <- Vector
"""
    subassign!(C::GBMatrix, A::GBMatrix, I, J; kwargs...)::GBMatrix

Assign a submatrix of `A` to `C`. Equivalent to [`assign!`](@ref) except that
`size(mask) == size(A)`, whereas `size(mask) == size(C)` in `assign!`.

# Arguments
- `C::GBMatrix`: the matrix being subassigned to where `C[I,J] = A`.
- `A::GBMatrix`: the matrix being assigned to a submatrix of `C`.
- `I` and `J`: A colon, scalar, vector, or range indexing C.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: mask where
    `size(M) == size(A)`.
- `accum::Union{Nothing, Function} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Union{Nothing, Descriptor} = nothing`

# Returns
- `GBMatrix`: The input matrix A.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `size(A) != (max(I), max(J))` or `size(A) != size(mask)`.
"""
function subassign!(
    C::AbstractGBArray, A::GBArrayOrTranspose, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    _canbeoutput(C) || throw(ShallowException())
    # before we make I and J into GraphBLAS internal types
    # get their size to check if A should be reshaped from nx1 -> 1xn
    ni_sizecheck = I isa Colon ? size(C, 1) : length(I)
    nj_sizecheck = J isa Colon ? size(C, 2) : length(J)
    I, ni = idx(I)
    J, nj = idx(J)
    desc = _handledescriptor(desc; in1=A)
    mask = _handlemask!(desc, mask)
    I = decrement!(I)
    J = decrement!(J)
    rereshape = false
    sz1 = size(A, 1)
    # reshape A: nx1 -> 1xn
    if A isa GBVector && (ni_sizecheck == size(A, 2) && nj_sizecheck == sz1)
        @wraperror LibGraphBLAS.GxB_Matrix_reshape(parent(A), true, 1, sz1, C_NULL)
        rereshape = true
    end
    @wraperror LibGraphBLAS.GxB_Matrix_subassign(C, mask, 
        _handleaccum(accum, eltype(C)), parent(A), I, ni, J, nj, desc)
    if rereshape # undo the reshape. Need size(A, 2) here
        @wraperror LibGraphBLAS.GxB_Matrix_reshape(
        parent(A), true, sz1, 1, C_NULL)
    end
    increment!(I)
    increment!(J)
    return A
end

function subassign!(C::AbstractGBArray{T}, x, I, J;
    mask = nothing, accum = nothing, desc = nothing
) where {T}
    _canbeoutput(C) || throw(ShallowException())
    x = typeof(x) === T ? x : convert(T, x)
    I, ni = idx(I)
    J, nj = idx(J)
    I = decrement!(I)
    J = decrement!(J)
    desc = _handledescriptor(desc)
    mask = _handlemask!(desc, mask)
    _subassign(C, x, I, ni, J, nj, mask, _handleaccum(accum, eltype(C)), desc)
    increment!(I)
    increment!(J)
    return x
end

function subassign!(C::AbstractGBArray, x::AbstractMatrix, I, J;
    mask = nothing, accum = nothing, desc = nothing)
    _canbeoutput(C) || throw(ShallowException())
    array = x isa VecOrMat ? x : collect(x)
    array = pack(array)
    subassign!(C, array, I, J; mask, accum, desc)
    unpack!(array; attachfinalizer = false)
    return x
end

function subassign!(C::AbstractGBArray, x::AbstractVector, I, J;
    mask = nothing, accum = nothing, desc = nothing)
    _canbeoutput(C) || throw(ShallowException())
    array = x isa VecOrMat ? x : collect(x)
    array = pack(array)
    subassign!(C, array, I, J; mask, accum, desc)
    unpack!(array; attachfinalizer = false)
    return x
end

function subassign!(C::AbstractGBArray, x::Union{SparseMatrixCSC, SparseVector}, I, J;
    mask = nothing, accum = nothing, desc = nothing)
    _canbeoutput(C) || throw(ShallowException())
    array = similar(C, eltype(x), size(x))
    array = pack!(array, x)
    subassign!(C, array, I, J; mask, accum, desc)
    unpack!(array, Sparse(); attachfinalizer = false)
    return x
end

"""
    assign!(C::GBMatrix, A::GBMatrix, I, J; kwargs...)::GBMatrix

Assign a submatrix of `A` to `C`. Equivalent to [`subassign!`](@ref) except that
`size(mask) == size(C)`, whereas `size(mask) == size(A) in `subassign!`.

# Arguments
- `C::GBMatrix`: the matrix being subassigned to where `C[I,J] = A`.
- `A::GBMatrix`: the matrix being assigned to a submatrix of `C`.
- `I` and `J`: A colon, scalar, vector, or range indexing C.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: mask where
    `size(M) == size(C)`.
- `accum::Union{Nothing, Function} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Union{Nothing, Descriptor} = nothing`

# Returns
- `GBMatrix`: The input matrix A.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `size(A) != (max(I), max(J))` or `size(C) != size(mask)`.
"""
function assign!(
    C::AbstractGBMatrix, A::GBArrayOrTranspose, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    _canbeoutput(C) || throw(ShallowException())
    I, ni = idx(I)
    J, nj = idx(J)
    desc = _handledescriptor(desc; in1=A)
    mask = _handlemask!(desc, mask)
    I = decrement!(I)
    J = decrement!(J)
    @wraperror LibGraphBLAS.GrB_Matrix_assign(C, mask, _handleaccum(accum, eltype(C)), parent(A), I, ni, J, nj, desc)
    increment!(I)
    increment!(J)
    return A
end

function assign!(C::AbstractGBArray{T}, x, I, J;
    mask = nothing, accum = nothing, desc = nothing
) where T
    _canbeoutput(C) || throw(ShallowException())
    x = typeof(x) === T ? x : convert(T, x)
    I, ni = idx(I)
    J, nj = idx(J)
    I = decrement!(I)
    J = decrement!(J)
    desc = _handledescriptor(desc)
    _assign(C, x, I, ni, J, nj, mask, _handleaccum(accum, eltype(C)), desc)
    increment!(I)
    increment!(J)
    return x
end

function Base.setindex!(
    C::AbstractGBMatrix,
    A,
    I,
    J;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    subassign!(C, A, I, J; mask, accum, desc)
end

#Help wanted: This isn't really centered for a lot of eltypes.
function Base.replace_in_print_matrix(A::AbstractGBMatrix, i::Integer, j::Integer, s::AbstractString)
    Base.isstored(A, i, j) ? s : Base.replace_with_centered_mark(s)
end

# AbstractGBVector functions:
#############################
function Base.size(v::AbstractGBVector)
    nrows = Ref{LibGraphBLAS.GrB_Index}()
    @wraperror LibGraphBLAS.GrB_Matrix_nrows(nrows, v)
    return (Int64(nrows[]),)
end

Base.eltype(::Type{AbstractGBVector{T}}) where{T} = T

function Base.deleteat!(v::AbstractGBVector, i)
    @wraperror LibGraphBLAS.GrB_Matrix_removeElement(v, decrement!(i), 0)
    return v
end

function Base.resize!(v::AbstractGBVector, n)
    @wraperror LibGraphBLAS.GrB_Matrix_resize(v, n, 1)
    return v
end

function LinearAlgebra.diag(A::AbstractGBMatrix{T}, k::Integer = 0; desc = nothing) where {T}
    m, n = size(A)
    if !(k in -m:n)
        s = 0
    elseif k >= 0
        s = min(m, n - k)
    else
        s = min(m + k, n)
    end
    v = GBVector{T}(s; A.fill)
    desc = _handledescriptor(desc; in1=A)
    if A isa Transpose
        k = -k
    end
    @wraperror LibGraphBLAS.GxB_Vector_diag(LibGraphBLAS.GrB_Vector(v), parent(A), k, desc)
    return v
end

# This does not conform to the normal definition with a lazy wrapper.
function LinearAlgebra.Diagonal(v::AbstractGBVector, k::Integer=0; desc = nothing)
    s = size(v, 1)
    C = GBMatrix{eltype(v)}(s, s; fill = v.fill)
    desc = _handledescriptor(desc)
    # Switch ptr to a Vector to trick GraphBLAS.
    # This is allowed since GrB_Vector is a GrB_Matrix internally.
    @wraperror LibGraphBLAS.GxB_Matrix_diag(C, LibGraphBLAS.GrB_Vector(v.p[]), k, desc)
    return C
end

# Type dependent functions build, setindex, getindex, and findnz:
for T ∈ valid_vec
    if T ∈ gxb_vec
        prefix = :GxB
    else
        prefix = :GrB
    end
    # Build functions
    func = Symbol(prefix, :_Matrix_build_, suffix(T))
    @eval begin
        function build!(v::AbstractGBVector{$T}, I::Vector{<:Integer}, X::Vector{$T}; combine = +)
            _canbeoutput(v) || throw(ShallowException())
            nnz(v) == 0 || throw(OutputNotEmptyError("Cannot build vector with existing elements"))
            I isa Vector || (I = collect(I))
            X isa Vector || (X = collect(X))
            length(X) == length(I) || DimensionMismatch("I and X must have the same length")
            combine = binaryop(combine, $T)
            decrement!(I)
            @wraperror LibGraphBLAS.$func(
                Ptr{LibGraphBLAS.GrB_Vector}(v.p[]), 
                I, 
                # TODO, fix this ugliness by switching to the GBVector build internally.
                zeros(LibGraphBLAS.GrB_Index, length(I)), 
                X, 
                length(X), 
                combine
            )
            increment!(I)
        end
    end
    # Setindex functions
    func = Symbol(prefix, :_Matrix_setElement_, suffix(T))
    @eval begin
        function Base.setindex!(v::AbstractGBVector{$T}, x, i::Integer)
            x = convert($T, x)
            return LibGraphBLAS.$func(v, x, LibGraphBLAS.GrB_Index(decrement!(i)), 0)
        end
    end
    # Getindex functions
    func = Symbol(prefix, :_Matrix_extractElement_, suffix(T))
    @eval begin
        function Base.getindex(v::GBVector{$T}, i::Integer)
            x = Ref{$T}()
            result = LibGraphBLAS.$func(x, v, LibGraphBLAS.GrB_Index(decrement!(i)), 0)
            if result == LibGraphBLAS.GrB_SUCCESS
                return x[]
            elseif result == LibGraphBLAS.GrB_NO_VALUE
                return v.fill
            else
                @wraperror result
            end
        end
    end
    # findnz functions
    func = Symbol(prefix, :_Matrix_extractTuples_, suffix(T))
    @eval begin
        function SparseArrays.findnz(v::AbstractGBVector{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            X = Vector{$T}(undef, nvals[])
            wait(v)
            @wraperror LibGraphBLAS.$func(I, C_NULL, X, nvals, v)
            nvals[] == length(I) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
            return increment!(I), X
        end
        function SparseArrays.nonzeros(v::GBVector{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
            X = Vector{$T}(undef, nvals[])
            wait(v)
            @wraperror LibGraphBLAS.$func(C_NULL, C_NULL, X, nvals, v)
            nvals[] == length(X) || throw(DimensionMismatch(""))
            return X
        end
        function SparseArrays.nonzeroinds(v::GBVector{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            wait(v)
            @wraperror LibGraphBLAS.$func(I, C_NULL, C_NULL, nvals, v)
            nvals[] == length(I) || throw(DimensionMismatch(""))
            return increment!(I)
        end
    end
end

function Base.isstored(v::AbstractGBVector, i::Int)
    result = LibGraphBLAS.GxB_Matrix_isStoredElement(v, decrement!(i), 0)
    if result == LibGraphBLAS.GrB_SUCCESS
        true
    elseif result == LibGraphBLAS.GrB_NO_VALUE
        false
    else
        @wraperror result
    end
end

# UDT versions of Vector functions, which just require one def of each.

function build!(v::AbstractGBVector{T}, I::Vector{<:Integer}, X::Vector{T}; combine = +) where {T}
    nnz(v) == 0 || throw(OutputNotEmptyError("Cannot build vector with existing elements"))
    _canbeoutput(v) || throw(ShallowException())
    I isa Vector || (I = collect(I))
    X isa Vector || (X = collect(X))
    length(X) == length(I) || DimensionMismatch("I and X must have the same length")
    combine = binaryop(combine, T)
    decrement!(I)
    @wraperror LibGraphBLAS.GrB_Matrix_build_UDT(
        Ptr{LibGraphBLAS.GrB_Vector}(v.p[]), 
        I, 
        # TODO, fix this ugliness by switching to the GBVector build internally.
        zeros(LibGraphBLAS.GrB_Index, length(I)), 
        X, 
        length(X), 
        combine
    )
    increment!(I)
end

function Base.setindex!(v::AbstractGBVector{T}, x, i::Integer) where {T}
    x = convert(T, x)
    return LibGraphBLAS.GrB_Matrix_setElement_UDT(v, Ref(x), LibGraphBLAS.GrB_Index(decrement!(i)), 0)
end

function Base.getindex(v::GBVector{T}, i::Integer) where {T}
    x = Ref{T}()
    result = LibGraphBLAS.GrB_Matrix_extractElement_UDT(x, v, LibGraphBLAS.GrB_Index(decrement!(i)), 0)
    if result == LibGraphBLAS.GrB_SUCCESS
        return x[]
    elseif result == LibGraphBLAS.GrB_NO_VALUE
        return v.fill
    else
        @wraperror result
    end
end

# findnz functions
function SparseArrays.findnz(v::AbstractGBVector{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
    I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    X = Vector{T}(undef, nvals[])
    wait(v)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(I, C_NULL, X, nvals, v)
    nvals[] == length(I) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
    return increment!(I), X
end
function SparseArrays.nonzeros(v::GBVector{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
    X = Vector{T}(undef, nvals[])
    wait(v)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(C_NULL, C_NULL, X, nvals, v)
    nvals[] == length(X) || throw(DimensionMismatch(""))
    return X
end
function SparseArrays.nonzeroinds(v::GBVector{T}) where {T}
    nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
    I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
    wait(v)
    @wraperror LibGraphBLAS.GrB_Matrix_extractTuples_UDT(I, C_NULL, C_NULL, nvals, v)
    nvals[] == length(I) || throw(DimensionMismatch(""))
    return increment!(I)
end

function build!(v::GBVector{T}, I::Vector{<:Integer}, x::T) where {T}
    _canbeoutput(v) || throw(ShallowException())
    nnz(v) == 0 || throw(OutputNotEmptyError("Cannot build vector with existing elements"))
    x = GBScalar(x)
    decrement!(I)
    @wraperror LibGraphBLAS.GxB_Matrix_build_Scalar(
            v,
            Vector{LibGraphBLAS.GrB_Index}(I),
            zeros(LibGraphBLAS.GrB_Index, length(I)),
            x,
            length(I)
        )
    increment!(I)
    return v
end

"""
    subassign(w::GBVector, u::GBVector, I; kwargs...)::GBVector

Assign a subvector of `w` to `u`. Return `u`. Equivalent to the matrix definition.
"""
function subassign!(w::AbstractGBVector{T, F}, u, I; mask = nothing, accum = nothing, desc = nothing) where {T, F}
    return subassign!(GBMatrix{T, F}(w.p, w.fill), u, I, UInt64[1]; mask, accum, desc)
end

"""
    assign(w::GBVector, u::GBVector, I; kwargs...)::GBVector

Assign a subvector of `w` to `u`. Return `u`. Equivalent to the matrix definition.
"""
function assign!(w::AbstractGBVector{T, F}, u, I; mask = nothing, accum = nothing, desc = nothing) where {T, F}
    return assign!(GBMatrix{T, F}(w.p, w.fill), u, I, UInt64[1]; mask, accum, desc)
end

# silly overload to help a bit with broadcasting.
function Base.setindex!(
    u::AbstractGBVector, x, I::Union{Vector, UnitRange, StepRange, Colon}, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    Base.subassign!(u, x, I; mask, accum, desc)
end
function Base.setindex!(
    u::AbstractGBVector, x, I;
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(u, x, I; mask, accum, desc)
    return x
end

function Base.show(io::IO, ::MIME"text/plain", A::AbstractGBArray) #fallback printing
    gxbprint(io, A)
end



function Base.getindex(
    A::AbstractGBMatrix, 
    i::Union{Vector, UnitRange, StepRange, Number, Colon}, 
    j::Union{Vector, UnitRange, StepRange, Number, Colon};
    mask = nothing, accum = nothing, desc = nothing
)
    return extract(A, i, j; mask, accum, desc)
end

function Base.getindex(
    A::AbstractGBMatrix,
    i::AbstractGBVector{<:Integer},
    j::AbstractGBVector{<:Integer};
    mask = nothing, accum = nothing, desc = nothing
)
    I = unpack!(i, Dense(); attachfinalizer = false)
    J = unpack!(j, Dense(); attachfinalizer = false)
    x = extract(A, I, J; mask, accum, desc)
    pack!(i, I, false)
    pack!(j, J, false)
    return x
end

"""
    setfill!(A::AbstractGBArray{T, N, F}, x::F)

Modify the fill value of `A`. 
The fill type of `A` and the type of `x` must be the same.
"""
function setfill!(A::AbstractGBArray, x)
    A.fill = x
end

"""
    setfill(A::AbstractGBArray{T, N, F}, x::F2)

Create a new AbstractGBArray with the same underlying data but a new fill `x`.
The fill type of `A` and the type of `x` may be different.
"""
function setfill(A::AbstractGBArray, x) # aliasing form.
    B = similar(A; fill=x)
    B.p = A.p
    return B
end

getfill(A::AbstractGBArray) = A.fill
getfill(A::LinearAlgebra.AdjOrTrans{<:Any, <:AbstractGBArray}) = getfill(parent(A))

function Base.:(==)(A::GBArrayOrTranspose, B::GBArrayOrTranspose)
    A === B && return true
    size(A) == size(B) || return false
    getfill(A) == getfill(B) || return false
    nnz(A) == nnz(B) || return false
    C = emul(A, B, ==)
    nnz(C) == nnz(A) || return false
    nnz(C) == 0 && return true
    return reduce(∧, C, dims=:, init=true)
end