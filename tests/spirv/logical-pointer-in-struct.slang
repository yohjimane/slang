//TEST:SIMPLE(filecheck=CHECK):-target spirv-asm -entry computeMain -stage compute -emit-spirv-directly -O0
//TEST(compute, vulkan):COMPARE_COMPUTE(filecheck-buffer=BUF):-vk -output-using-type -emit-spirv-directly

// Regression test for https://github.com/shader-slang/slang/issues/13206.
//
// A struct with a field that is a pointer in a *logical* SPIR-V storage class -- here
// `Ptr<float, Access.ReadWrite, GroupShared>`, which lowers to a `Workgroup` pointer -- is
// constructed as a local and read back through its subscript. Because the subscript accessor
// takes `this` by value, reading the field used to load the whole struct as an SSA value and then
// `OpCompositeExtract` the pointer out of it, which logical addressing forbids ("Instruction may
// not return a logical pointer"); slangc emitted it with no diagnostic. SPIR-V legalization now
// sinks the load through the field projection so the pointer is read directly via
// `OpAccessChain`/`OpLoad` and never becomes a composite operand.

struct View<let A : AddressSpace>
{
    Ptr<float, Access.ReadWrite, A> data;
    __subscript(int i) -> float
    {
        get { return data[i]; }
        [nonmutating] set { data[i] = newValue; }
    }
}

// A nested aggregate exercises projection-sinking through more than one level.
struct Outer
{
    View<AddressSpace.GroupShared> view;
}

groupshared float gsA[64];

//TEST_INPUT:ubuffer(data=[0 0], stride=4):out,name=outputBuffer
RWStructuredBuffer<float> outputBuffer;

// The logical pointer must be read through an address, never extracted from a composite value.
// CHECK: OpEntryPoint
// CHECK-NOT: OpCompositeExtract

[shader("compute")]
[numthreads(1, 1, 1)]
void computeMain()
{
    View<AddressSpace.GroupShared> a;
    a.data = __getAddress(gsA[0]);
    a[0] = 1.0f;
    // BUF: 1
    outputBuffer[0] = a[0];

    Outer o;
    o.view.data = __getAddress(gsA[1]);
    o.view[0] = 2.0f;
    // BUF: 2
    outputBuffer[1] = o.view[0];
}
