const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("stb_image.h");
});

const Shader = @import("shader_s.zig").Shader;
const std = @import("std");
const panic = std.debug.panic;

// Settings
const screen_width: u32 = 800;
const screen_height: u32 = 600;

const vertex_shader_source: [:0]const u8 =
\\#version 330 core
\\layout (location = 0) in vec3 aPos;
\\void main() {
\\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
\\};
;

const fragment_shader_source: [:0]const u8 =
\\#version 330 core
\\out vec4 FragColor;
\\void main() {
\\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
\\}
;

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
    // vertex shader
    const our_shader = try Shader.init("shaders/4_1_vshader.glsl", "shaders/4_2_fshader.glsl");
    defer our_shader.free();

    // Set up vertex data (and buffer(s)) and configure vertex attributes
    const vertices = [_]f32{
        // positions       // colors        // texture coords
         0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0, // top right
         0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0, // bottom left
        -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0  // top left        
    };
    const indices = [_]u32{
        0, 1, 3, // first Triangle
        1, 2, 3, // second Triangle
    };
    var vbo: u32 = undefined;
    var vao: u32 = undefined;
    var ebo: u32 = undefined;
    c.glGenVertexArrays(1, &vao);
    // optional: de-allocate all resources once they've outlived their purpose
    defer c.glDeleteVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);
    // optional: de-allocate all resources once they've outlived their purpose
    defer c.glDeleteBuffers(1, &vbo);
    c.glGenBuffers(1, &ebo);
    // optional: de-allocate all resources once they've outlived their purpose
    defer c.glDeleteBuffers(1, &ebo);
    // bind the Vertex Array Object first, then binmd the set vertex buffer(s), and then configure
    // vertex attribute(s).
    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(@TypeOf(vertices)), &vertices,
            c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(@TypeOf(indices)), &indices,
            c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);
    // color attribute
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32),
            @intToPtr(*c_void, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
    // texture coord attribute
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32),
            @intToPtr(*c_void, 6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    // Load and create texture
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channel_count: c_int = undefined;
    
    var texture1: u32 = undefined;
    var texture2: u32 = undefined;
    // texture 1
    c.glGenTextures(1, &texture1);
    c.glBindTexture(c.GL_TEXTURE_2D, texture1);
    // set the texture wrapping parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    // set texture filtering parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    // load image, create texture and generate mipmaps
    var data = c.stbi_load("resources/textures/container.jpg", &width, &height, &channel_count, 0);

    if (data == null) {
        panic("Failed to load texture 1\n", .{});
    }
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE,
            data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    c.stbi_image_free(data);

    // texture 2
    c.glGenTextures(1, &texture2);
    c.glBindTexture(c.GL_TEXTURE_2D, texture2);
    // set the texture wrapping parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    // set texture filtering parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    // load image, create texture and generate mipmaps
    c.stbi_set_flip_vertically_on_load(1);  
    data = c.stbi_load("resources/textures/awesomeface.png", &width, &height, &channel_count, 0);

    if (data == null) {
        panic("Failed to load texture 1\n", .{});
    }
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE,
            data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    c.stbi_image_free(data);

    // tell OpenGL for each sampler to which texture unit it belongs to (only has to be done once)
    our_shader.use();
    // either set it manually like so:
    c.glUniform1i(c.glGetUniformLocation(our_shader.id, "texture1"), 0);
    // or set it via the texture class
    our_shader.setInt("texture2", 1);

    // Render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // Input
        processInput(window);

        // Render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Bind texture
        // activate the texture unit first before binding texture
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        // Render the triangle
        our_shader.use();
        c.glBindVertexArray(vao);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

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
