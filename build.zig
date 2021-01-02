const Builder = @import("std").build.Builder;

const targets = [_]Target{
    .{
        .name = "1_1",
        .path = "src/1_1_hello_window.zig",
        .description = "Hello Window: Create an OpenGL context and application window to draw in.",
    },
    .{
        .name = "2_1",
        .path = "src/2_1_hello_triangle.zig",
        .description = "Hello Triangle: Render your first triangle using OpenGL.",
    },
    .{
        .name = "2_2",
        .path = "src/2_2_hello_triangle_indexed.zig",
        .description = "Hello Triangle Indexed: Draw two triangles using Element Buffer Object.",
    },
};

pub fn build(b: *Builder) void {
    for (targets) |target| {
        target.build(b);
    }
}

const Target = struct {
    name: []const u8,
    path: []const u8,
    description: []const u8,

    pub fn build(self: Target, b: *Builder) void {
        const exe = b.addExecutable(self.name, self.path);
        exe.setBuildMode(b.standardReleaseOptions());

        exe.addIncludeDir("./deps/include/");
        exe.addLibPath("./deps/lib/");

        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("glad");
        exe.linkSystemLibrary("c");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");

        b.default_step.dependOn(&exe.step);
        b.step(self.name, self.description).dependOn(&exe.run().step);
    }
};
