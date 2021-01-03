const c = @cImport({
    @cInclude("glad/glad.h");
});

const std = @import("std");
const cwd = std.fs.cwd;
const eql = std.mem.eql;
const page_allocator = std.heap.page_allocator;
const panic = std.debug.panic;
const OpenFlags = std.fs.File.OpenFlags;

pub const Shader = struct {
    id: c_uint,

    pub fn init(vertex_path: []const u8, fragment_path: []const u8) !Shader {
        const vertex_shader_file = try cwd().openFile(vertex_path,
                OpenFlags{.read = true, .write = false});
        defer vertex_shader_file.close();

        const fragment_shader_file = try cwd().openFile(fragment_path,
                OpenFlags{.read = true, .write = false});
        defer fragment_shader_file.close();

        const vertex_code = try page_allocator.alloc(u8, try vertex_shader_file.getEndPos());
        defer page_allocator.free(vertex_code);
        const fragment_code = try page_allocator.alloc(u8, try fragment_shader_file.getEndPos());
        defer page_allocator.free(fragment_code);

        const vertex_shader_length = try vertex_shader_file.read(vertex_code);
        const fragment_shader_length = try fragment_shader_file.read(fragment_code);

        const vertex = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(vertex, 1, &vertex_code.ptr, null);
        c.glCompileShader(vertex);
        checkCompileErrors(vertex, CompileType.vertex);
        defer c.glDeleteShader(vertex);
        // fragment shader
        const fragment = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(fragment, 1, &fragment_code.ptr, null);
        c.glCompileShader(fragment);
        checkCompileErrors(fragment, CompileType.fragment);
        defer c.glDeleteShader(fragment);
        //link shaders
        const shader_program = c.glCreateProgram();
        c.glAttachShader(shader_program, vertex);
        c.glAttachShader(shader_program, fragment);
        c.glLinkProgram(shader_program);
        // check for linking errors
        checkCompileErrors(shader_program, CompileType.program);

        return Shader{.id = shader_program};
    }

    pub fn free(self: Shader) void {
        // optional: de-allocate all resources once they've outlived their purpose
        c.glDeleteProgram(self.id);
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name), @intCast(c_int, @boolToInt(value)));
    }

    pub fn setInt(self: Shader, name: [:0]const u8, value: i32) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name), @intCast(c_int, value));
    }

    pub fn setFloat(self: Shader, name: [:0]const u8, val: f32) void {
        c.glUniform1f(c.glGetUniformLocation(self.id, name), value);
    }

    fn checkCompileErrors(shader: c_uint, compile_type: CompileType) void {
        var success: i32 = undefined;
        var info_log: [1024]u8 = undefined;
        if (compile_type != CompileType.program) {
            c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
            if (success == 0) {
                c.glGetShaderInfoLog(shader, 512, null, &info_log);
                panic("ERROR::SHADER_COMPILATION_ERROR of type: {}\n{}\n",
                        .{compile_type, info_log});
            }
        } else {
            c.glGetProgramiv(shader, c.GL_LINK_STATUS, &success);
            if (success == 0) {
                c.glGetProgramInfoLog(shader, 1024, null, &info_log);
                panic("ERROR::PROGRAM_LINKING_ERROR of type: {}\n{}\n",
                        .{compile_type, info_log});
            }
        }
    }
};

const CompileType = enum {
    vertex,
    fragment,
    program
};