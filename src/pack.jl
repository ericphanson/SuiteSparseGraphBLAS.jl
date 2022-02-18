function _packdensematrix!(A::GBVecOrMat{T}, M::DenseVecOrMat; desc = nothing) where {T}
    desc = _handledescriptor(desc)
    Csize = length(A) * sizeof(T)
    values = Ref{Ptr{Cvoid}}(pointer(M))
    isuniform = false
    libgb.GxB_Matrix_pack_FullC(
        A.p,
        values,
        Csize,
        isuniform,
        desc
    )
    return A
end

function _packcscmatrix!(
    A::GBVecOrMat{T},
    colptr::Vector{Ti},
    rowidx::Vector{Ti},
    values::Vector{T};
    desc = nothing
    ) where {T, Ti}
    colptr .-= 1
    rowidx .-= 1
    colptrsize = length(colptr) * sizeof(libgb.GrB_Index)
    rowidxsize = length(rowidx) * sizeof(libgb.GrB_Index)
    valsize = length(values) * sizeof(T)
    colptr = Ref{Ptr{libgb.GrB_Index}}(pointer(colptr))
    rowidx = Ref{Ptr{libgb.GrB_Index}}(pointer(rowidx))
    values = Ref{Ptr{Cvoid}}(pointer(values))
    desc = _handledescriptor(desc)

    x = libgb.GxB_Matrix_pack_CSC(
        A,
        colptr,
        rowidx,
        values,
        colptrsize,
        rowidxsize,
        valsize,
        false,
        false,
        desc
    )
    return A
end

function _packcsrmatrix!(
    A::GBVecOrMat{T},
    rowptr::Vector{Ti},
    colidx::Vector{Ti},
    values::Vector{T};
    desc = nothing
    ) where {T, Ti}
    rowptr .-= 1
    colidx .-= 1
    rowptrsize = length(rowptr) * sizeof(libgb.GrB_Index)
    colidxsize = length(colidx) * sizeof(libgb.GrB_Index)
    valsize = length(values) * sizeof(T)
    rowptr = Ref{Ptr{libgb.GrB_Index}}(pointer(rowptr))
    colidx = Ref{Ptr{libgb.GrB_Index}}(pointer(colidx))
    values = Ref{Ptr{Cvoid}}(pointer(values))
    desc = _handledescriptor(desc)

    libgb.GxB_Matrix_pack_CSC(
        A,
        rowptr,
        colidx,
        values,
        rowptrsize,
        colidxsize,
        valsize,
        false,
        false,
        desc
    )
    return A
end

function _makeshallow!(A::GBVecOrMat)
    ccall((:GB_make_shallow, libgraphblas), Cvoid, (libgb.GrB_Matrix,), A)
end