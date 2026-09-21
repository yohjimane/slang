//TEST:SIMPLE(filecheck=POINT):-target spirv-asm -entry pointMain -stage geometry
//TEST:SIMPLE(filecheck=LINE):-target spirv-asm -entry lineMain -stage geometry
//TEST:SIMPLE(filecheck=LINEADJ):-target spirv-asm -entry lineAdjMain -stage geometry
//TEST:SIMPLE(filecheck=TRIADJ):-target spirv-asm -entry triangleAdjMain -stage geometry
//TEST:SIMPLE(filecheck=TRI):-target spirv-asm -entry triangleMain -stage geometry
//TEST:SIMPLE(filecheck=NONEMPTY):-target spirv-asm -entry nonEmptyMain -stage geometry
//TEST:SIMPLE(filecheck=POINTGLSL):-target glsl -entry pointMain -stage geometry
//TEST:SIMPLE(filecheck=LINEGLSL):-target glsl -entry lineMain -stage geometry
//TEST:SIMPLE(filecheck=LINEADJGLSL):-target glsl -entry lineAdjMain -stage geometry
//TEST:SIMPLE(filecheck=TRIADJGLSL):-target glsl -entry triangleAdjMain -stage geometry

// A geometry shader's declared input primitive topology must survive an empty input element
// struct. Regression test for https://github.com/shader-slang/slang/issues/13193.
// The fix records the topology on the entry-point function for every topology op, so all five
// (point/line/lineadj/triangle/triangleadj) are checked against `-target spirv-asm`;
// point/line/lineadj/triangleadj are additionally checked against `-target glsl`. The
// point/line/lineadj cases add `-NOT: Triangles` to lock out the previous wrong default;
// triangleadj deliberately omits it because the correct `InputTrianglesAdjacency` /
// `triangles_adjacency` output itself contains the substring `Triangles`.

struct Empty {};
struct Vertex { float4 position : SV_Position; };

// POINT: OpExecutionMode {{.*}} InputPoints
// POINT-NOT: OpExecutionMode {{.*}} Triangles
// POINTGLSL: layout(points) in;
// POINTGLSL-NOT: layout(triangles) in;
[maxvertexcount(1)]
void pointMain(point Empty input[1], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}

// LINE: OpExecutionMode {{.*}} InputLines
// LINE-NOT: OpExecutionMode {{.*}} Triangles
// LINEGLSL: layout(lines) in;
// LINEGLSL-NOT: layout(triangles) in;
[maxvertexcount(2)]
void lineMain(line Empty input[2], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}

// LINEADJ: OpExecutionMode {{.*}} InputLinesAdjacency
// LINEADJ-NOT: OpExecutionMode {{.*}} Triangles
// LINEADJGLSL: layout(lines_adjacency) in;
// LINEADJGLSL-NOT: layout(triangles) in;
[maxvertexcount(2)]
void lineAdjMain(lineadj Empty input[4], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}

// No `-NOT: Triangles` here: the correct `InputTrianglesAdjacency` output contains that substring.
// TRIADJ: OpExecutionMode {{.*}} InputTrianglesAdjacency
// TRIADJGLSL: layout(triangles_adjacency) in;
[maxvertexcount(3)]
void triangleAdjMain(triangleadj Empty input[6], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}

// Same-topology sanity check, not a regression guard: `triangle` is exactly the erroneous default,
// so this emits `Triangles` with or without the fix. It only guards against triangle input
// disappearing entirely.
// TRI: OpExecutionMode {{.*}} Triangles
[maxvertexcount(3)]
void triangleMain(triangle Empty input[3], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}

// Non-empty input control: the parameter survives to ir-glsl-legalize.
struct NonEmpty { float4 pos : Position; };

// NONEMPTY: OpExecutionMode {{.*}} InputPoints
// NONEMPTY-NOT: OpExecutionMode {{.*}} Triangles
[maxvertexcount(1)]
void nonEmptyMain(point NonEmpty input[1], inout PointStream<Vertex> output)
{
    Vertex v;
    v.position = float4(0, 0, 0, 1);
    output.Append(v);
}
