# AbstractGBArray functions:
function SparseArrays.nnz(A::AbsGBArrayOrTranspose)
    nvals = Ref{LibGraphBLAS.GrB_Index}()
    @wraperror LibGraphBLAS.GrB_Matrix_nvals(nvals, gbpointer(parent(A)))
    return Int64(nvals[])
end

Base.eltype(::Type{AbstractGBArray{T}}) where{T} = T

"""
    clear!(v::GBVector)
    clear!(A::GBMatrix)

Clear all the entries from the GBArray.
Does not modify the type or dimensions.
"""
clear!(A::AbsGBArrayOrTranspose) = @wraperror LibGraphBLAS.GrB_Matrix_clear(gbpointer(parent(A))); return nothing

# AbstractGBMatrix functions:
#############################

function build(A::AbstractGBMatrix{T}, I::AbstractVector, J::AbstractVector, x::T) where {T}
    nnz(A) == 0 || throw(OutputNotEmptyError("Cannot build matrix with existing elements"))
    length(I) == length(J) || DimensionMismatch("I, J and X must have the same length")
    x = GBScalar(x)

    @wraperror LibGraphBLAS.GxB_Matrix_build_Scalar(
        gbpointer(A),
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
    @wraperror LibGraphBLAS.GrB_Matrix_nrows(nrows, gbpointer(A))
    @wraperror LibGraphBLAS.GrB_Matrix_ncols(ncols, gbpointer(A))
    return (Int64(nrows[]), Int64(ncols[]))
end

function Base.deleteat!(A::AbstractGBMatrix, i, j)
    @wraperror LibGraphBLAS.GrB_Matrix_removeElement(A, decrement!(i), decrement!(j))
    return A
end

function Base.resize!(A::AbstractGBMatrix, nrows_new, ncols_new)
    @wraperror LibGraphBLAS.GrB_Matrix_resize(gbpointer(A), nrows_new, ncols_new)
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
        function build(A::AbstractGBMatrix{$T}, I::AbstractVector{<:Integer}, J::AbstractVector{<:Integer}, X::AbstractVector{$T};
                combine = +
            )
            combine = BinaryOp(combine)($T)
            I isa Vector || (I = collect(I))
            J isa Vector || (J = collect(J))
            X isa Vector || (X = collect(X))
            nnz(A) == 0 || throw(OutputNotEmptyError("Cannot build matrix with existing elements"))
            length(X) == length(I) == length(J) ||
                DimensionMismatch("I, J and X must have the same length")
            decrement!(I)
            decrement!(J)
            @wraperror LibGraphBLAS.$func(
                gbpointer(A),
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
            @wraperror LibGraphBLAS.$func(gbpointer(A), x, LibGraphBLAS.GrB_Index(decrement!(i)), LibGraphBLAS.GrB_Index(decrement!(j)))
            return x
        end
    end
    # Getindex functions
    func = Symbol(prefix, :_Matrix_extractElement_, suffix(T))
    @eval begin
        function Base.getindex(A::AbstractGBMatrix{$T}, i::Int, j::Int)
            x = Ref{$T}()
            result = LibGraphBLAS.$func(x, gbpointer(A), decrement!(i), decrement!(j))
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
            @wraperror LibGraphBLAS.$func(I, J, X, nvals, gbpointer(A))
            nvals[] == length(I) == length(J) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
            return increment!(I), increment!(J), X
        end
        function SparseArrays.nonzeros(A::AbstractGBMatrix{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
            X = Vector{$T}(undef, nvals[])
            wait(A)
            @wraperror LibGraphBLAS.$func(C_NULL, C_NULL, X, nvals, gbpointer(A))
            nvals[] == length(X) || throw(DimensionMismatch(""))
            return X
        end
        function SparseArrays.nonzeroinds(A::AbstractGBMatrix{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(A))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            J = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            wait(A)
            @wraperror LibGraphBLAS.$func(I, J, C_NULL, nvals, gbpointer(A))
            nvals[] == length(I) == length(J) || throw(DimensionMismatch(""))
            return increment!(I), increment!(J)
        end
    end
end

for T ∈ valid_vec
    func = Symbol(:GxB_Matrix_subassign_, suffix(T))
    @eval begin
        function _subassign(C::AbstractGBMatrix{$T}, x, I, ni, J, nj, mask, accum, desc)
            @wraperror LibGraphBLAS.$func(gbpointer(C), mask, accum, x, I, ni, J, nj, desc)
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
    # TODO: Update when upstream.
    # this is less than ideal. But required for isstored.
    # a new version of graphBLAS will replace this with Matrix_extractElement_Structural
    func = Symbol(prefix, :_Matrix_extractElement_, suffix(T))
    @eval begin
        function Base.isstored(A::AbstractGBMatrix{$T}, i::Int, j::Int)
            result = LibGraphBLAS.$func(Ref{$T}(), gbpointer(A), decrement!(i), decrement!(j))
            if result == LibGraphBLAS.GrB_SUCCESS
                true
            elseif result == LibGraphBLAS.GrB_NO_VALUE
                false
            else
                @wraperror result
            end
        end
    end
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
- `accum::Union{Nothing, Function, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Union{Nothing, Descriptor} = nothing`

# Returns
- `GBMatrix`: The input matrix A.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `size(A) != (max(I), max(J))` or `size(A) != size(mask)`.
"""
function subassign!(
    C::AbstractGBMatrix, A::GBArray, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    I, ni = idx(I)
    J, nj = idx(J)
    mask === nothing && (mask = C_NULL)
    I = decrement!(I)
    J = decrement!(J)
    # we know A isn't adjoint/transpose on input
    desc = _handledescriptor(desc; in1=A)
    @wraperror LibGraphBLAS.GxB_Matrix_subassign(gbpointer(C), mask, getaccum(accum, eltype(C)), gbpointer(parent(A)), I, ni, J, nj, desc)
    increment!(I)
    increment!(J)
    return A
end

function subassign!(C::AbstractGBArray, x, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    I, ni = idx(I)
    J, nj = idx(J)
    I = decrement!(I)
    J = decrement!(J)
    desc = _handledescriptor(desc)
    mask, accum = _handlenothings(mask, accum)
    _subassign(C, x, I, ni, J, nj, mask, getaccum(accum, eltype(C)), desc)
    increment!(I)
    increment!(J)
end

function subassign!(C::AbstractGBArray, x::AbstractArray, I, J;
    mask = nothing, accum = nothing, desc = nothing)
    as(GBMatrix, x) do array
        subassign!(C, array, I, J; mask, accum, desc)
    end
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
- `accum::Union{Nothing, Function, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Union{Nothing, Descriptor} = nothing`

# Returns
- `GBMatrix`: The input matrix A.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `size(A) != (max(I), max(J))` or `size(C) != size(mask)`.
"""
function assign!(
    C::AbstractGBMatrix, A::AbstractGBVector, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    I, ni = idx(I)
    J, nj = idx(J)
    mask === nothing && (mask = C_NULL)
    I = decrement!(I)
    J = decrement!(J)
    # we know A isn't adjoint/transpose on input
    desc = _handledescriptor(desc)
    @wraperror LibGraphBLAS.GrB_Matrix_assign(gbpointer(C), mask, getaccum(accum, eltype(C)), gbpointer(A), I, ni, J, nj, desc)
    increment!(I)
    increment!(J)
    return A
end

function assign!(C::AbstractGBArray, x, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    I = decrement!(I)
    J = decrement!(J)
    desc = _handledescriptor(desc)
    _assign(gbpointer(C), x, I, ni, J, nj, mask, getaccum(accum, eltype(C)), desc)
    increment!(I)
    increment!(J)
end

# setindex! uses subassign rather than assign.
function Base.setindex!(
    C::AbstractGBMatrix, A, ::Colon, J;
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(C, A, ALL, J; mask, accum, desc)
end
function Base.setindex!(
    C::AbstractGBMatrix, A, I, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(C, A, I, ALL; mask, accum, desc)
end
function Base.setindex!(
    C::AbstractGBMatrix, A, ::Colon, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(C, A, ALL, ALL; mask, accum, desc)
end

function Base.setindex!(
    C::AbstractGBMatrix,
    A,
    I::Union{Vector, UnitRange, StepRange, Number},
    J::Union{Vector, UnitRange, StepRange, Number};
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
    @wraperror LibGraphBLAS.GrB_Matrix_nrows(nrows, gbpointer(v))
    return (Int64(nrows[]),)
end

Base.eltype(::Type{AbstractGBVector{T}}) where{T} = T

function Base.deleteat!(v::AbstractGBVector, i)
    @wraperror LibGraphBLAS.GrB_Matrix_removeElement(gbpointer(v), decrement!(i), 1)
    return v
end

function Base.resize!(v::AbstractGBVector, n)
    @wraperror LibGraphBLAS.GrB_Matrix_resize(gbpointer(v), n, 1)
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
    @wraperror LibGraphBLAS.GxB_Vector_diag(LibGraphBLAS.GrB_Vector(gbpointer(v)), gbpointer(parent(A)), k, desc)
    return v
end

# This does not conform to the normal definition with a lazy wrapper.
function LinearAlgebra.Diagonal(v::AbstractGBVector, k::Integer=0; desc = nothing)
    s = size(v, 1)
    C = GBMatrix{eltype(v)}(s, s; fill = v.fill)
    desc = _handledescriptor(desc)
    # Switch ptr to a Vector to trick GraphBLAS.
    # This is allowed since GrB_Vector is a GrB_Matrix internally.
    @wraperror LibGraphBLAS.GxB_Matrix_diag(C, Ptr{LibGraphBLAS.GrB_Vector}(gbpointer(v)), k, desc)
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
        function build(v::AbstractGBVector{$T}, I::Vector{<:Integer}, X::Vector{$T}; combine = +)
            nnz(v) == 0 || throw(OutputNotEmptyError("Cannot build vector with existing elements"))
            I isa Vector || (I = collect(I))
            X isa Vector || (X = collect(X))
            length(X) == length(I) || DimensionMismatch("I and X must have the same length")
            combine = BinaryOp(combine)($T)
            decrement!(I)
            @wraperror LibGraphBLAS.$func(
                Ptr{LibGraphBLAS.GrB_Vector}(gbpointer(v)), 
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
            return LibGraphBLAS.$func(gbpoitner(v), x, LibGraphBLAS.GrB_Index(decrement!(i)), 0)
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
            @wraperror LibGraphBLAS.$func(I, C_NULL, X, nvals, gbpointer(v))
            nvals[] == length(I) == length(X) || throw(DimensionMismatch("length(I) != length(X)"))
            return increment!(I), X
        end
        function SparseArrays.nonzeros(v::GBVector{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
            X = Vector{$T}(undef, nvals[])
            wait(v)
            @wraperror LibGraphBLAS.$func(C_NULL, C_NULL, X, nvals, gbpointer(v))
            nvals[] == length(X) || throw(DimensionMismatch(""))
            return X
        end
        function SparseArrays.nonzeroinds(v::GBVector{$T})
            nvals = Ref{LibGraphBLAS.GrB_Index}(nnz(v))
            I = Vector{LibGraphBLAS.GrB_Index}(undef, nvals[])
            wait(v)
            @wraperror LibGraphBLAS.$func(I, C_NULL, C_NULL, nvals, gbpointer(v))
            nvals[] == length(I) || throw(DimensionMismatch(""))
            return increment!(I)
        end
    end
end

function build(v::GBVector{T}, I::Vector, x::T) where {T}
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

function Base.setindex!(
    u::AbstractGBVector, x, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(u, x, ALL; mask, accum, desc)
    return nothing
end
# silly overload to help a bit with broadcasting.
function Base.setindex!(
    u::AbstractGBVector, x, I::Union{Vector, UnitRange, StepRange, Colon}, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    Base.setindex!(u, x, I; mask, accum, desc)
end
function Base.setindex!(
    u::AbstractGBVector, x, I::Union{Vector, UnitRange, StepRange};
    mask = nothing, accum = nothing, desc = nothing
)
    subassign!(u, x, I; mask, accum, desc)
    return nothing
end