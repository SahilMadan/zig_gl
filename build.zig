const Builder = @import("std").build.Builder;

const Dependencies = enum {
    stb_image,
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
    dependencies: []const Dependencies,

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

        for (self.dependencies) |dependency| {
            switch (dependency) {
                Dependencies.stb_image => {
                    exe.addCSourceFile("./deps/src/stb_image.c", &[_][]const u8{"-std=c99"});
                }
            }
        }

        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        b.step(self.name, self.description).dependOn(&exe.run().step);
    }
};

const targets = [_]Target{
    .{
        .name = "1_1",
        .path = "src/1_1_hello_window.zig",
        .description = "Hello Window: Create an OpenGL context and application window to draw in.",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "2_1",
        .path = "src/2_1_hello_triangle.zig",
        .description = "Hello Triangle: Render your first triangle using OpenGL.",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "2_2",
        .path = "src/2_2_hello_triangle_indexed.zig",
        .description = "Hello Triangle Indexed: Draw two triangles using Element Buffer Object.",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "3_1",
        .path = "src/3_1_shaders_uniform.zig",
        .description = "Shaders Uniform: Set triangle color through shader uniform.",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "3_2",
        .path = "src/3_2_shaders_interpolation.zig",
        .description = "Shaders Interpolation: Set & interpolate triangle color between vertices.",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "3_3",
        .path = "src/3_3_shaders_class.zig",
        .description = "Shaderrs Class: TODO DESCRIPTION",
        .dependencies = &[_]Dependencies{},
    },
    .{
        .name = "4_1",
        .path = "src/4_1_textures.zig",
        .description = "Shaderrs Class: TODO DESCRIPTION",
        .dependencies = &[_]Dependencies{Dependencies.stb_image},
    },
};
