//TEST:SIMPLE(filecheck=CHECK):-target spirv-asm -entry computeMain -stage compute -emit-spirv-directly -O0

// Array variant of https://github.com/shader-slang/slang/issues/13206.
//
// An array of structs, each carrying a logical-storage-class pointer, is indexed and then
// field-read. This exercises the array recursion in the "transitively contains a logical pointer"
// predicate (the nesting #9062 missed) and the `getElement` case of the projection-sinking, so the
// element is projected via `OpAccessChain` rather than materialized as a composite value.

struct View<let A : AddressSpace>
{
    Ptr<float, Access.ReadWrite, A> data;
    __subscript(int i) -> float
    {
        get { return data[i]; }
        [nonmutating] set { data[i] = newValue; }
    }
}

groupshared float gsA[64];
groupshared float gsB[64];

//TEST_INPUT:ubuffer(data=[0 0], stride=4):out,name=outputBuffer
RWStructuredBuffer<float> outputBuffer;

// CHECK: OpEntryPoint
// CHECK-NOT: OpCompositeExtract

[shader("compute")]
[numthreads(1, 1, 1)]
void computeMain()
{
    View<AddressSpace.GroupShared> views[2];
    views[0].data = __getAddress(gsA[0]);
    views[1].data = __getAddress(gsB[0]);
    views[0][0] = 3.0f;
    views[1][0] = 4.0f;
    outputBuffer[0] = views[0][0];
    outputBuffer[1] = views[1][0];
}
