const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const warn = std.debug.warn;

// Settings
const screen_width: u32 = 800;
const screen_height: u32 = 600;

pub fn main() u8 {
    // GLFW: Initialize and configure
    if (c.glfwInit() == 0) {
        warn("Failed to initialize GLFW\n", .{});
        return 1;
    }
    defer c.glfwTerminate();

    // GLFW window creation
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var window = c.glfwCreateWindow(screen_width, screen_height, "LearnOpenGL", null, null);
    if (window == null) {
        warn("Failed to create GLFW window", .{});
        return 1;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    // glad: load all OpenGL function pointers
    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
        warn("Error loading glad", .{});
        return 1;
    }

    // Render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // Input
        processInput(window);

        // Render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

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
pub fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}
