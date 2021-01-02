const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const warn = std.debug.warn;

pub fn main() u8 {
    if (c.glfwInit() == 0) {
        warn("Failed to initialize GLFW\n", .{});
        return 1;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);

    var window = c.glfwCreateWindow(640, 480, "LearnOpenGL", null, null);
    if (window == null) {
        warn("Failed to create GLFW window", .{});
        return 1;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
        warn("Error loading glad", .{});
        return 1;
    }

    c.glViewport(0, 0, 800, 600);

    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}

pub fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}

pub fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}
