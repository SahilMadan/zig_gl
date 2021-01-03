const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const Shader = @import("shader_s.zig").Shader;
const std = @import("std");
const panic = std.debug.panic;
const sin = std.math.sin;

// Settings
const screen_width: u32 = 800;
const screen_height: u32 = 600;

pub fn main() !u8 {
    // GLFW: Initialize and configure
    if (c.glfwInit() == 0) {
        panic("Failed to initialize GLFW\n", .{});
    }
    defer c.glfwTerminate();

    // GLFW window creation
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var window = c.glfwCreateWindow(screen_width, screen_height, "LearnOpenGL", null, null);
    if (window == null) {
        panic("Failed to create GLFW window\n", .{});
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    // glad: load all OpenGL function pointers
    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
        panic("Error loading glad\n", .{});
    }

    // Build and compile our shader program
    const our_shader = try Shader.init("shaders/3_3_vshader.glsl", "shaders/3_3_fshader.glsl");
    defer our_shader.free();

    // Set up vertex data (and buffer(s)) and configure vertex attributes
    const vertices = [_]f32{
         // positions     // colors
         0.5, -0.5, 0.0,  1.0, 0.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,   // bottom left
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0    // top     
    };
    var vbo: u32 = undefined;
    var vao: u32 = undefined;
    c.glGenVertexArrays(1, &vao);
    // optional: de-allocate all resources once they've outlived their purpose
    defer c.glDeleteVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);
    // optional: de-allocate all resources once they've outlived their purpose
    defer c.glDeleteBuffers(1, &vbo);
    // bind the Vertex Array Object first, then binmd the set vertex buffer(s), and then configure
    // vertex attribute(s).
    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(@TypeOf(vertices)), &vertices,
            c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // color attribute
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32),
            @intToPtr(*c_void, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex
    // attribute's bound vertex buffer object so afterwards we can safely unbind
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    // You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but
    // this rarely happens. Modifying other VAOs requires a call to glBindVertexArray anyways so we
    // generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
    // c.glBindVertexArray(0);

    // Render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // Input
        processInput(window);

        // Render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Render the triangle
        our_shader.use();
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // GLFW: Swap buffers and poll IO events (keys pressed/released, mouse moved, etc.)
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}

/// Process all input: query GLFW whether relevant keys are pressed/released this frame and react
/// accordingly.
pub fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}

/// GLFW: Whenever the window size changed (by OS or user resize) this callback function executes
pub fn framebufferSizeCallback(
        window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}
