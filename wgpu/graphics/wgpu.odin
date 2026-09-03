package graphics

import "base:runtime"
import "core:log"
import "core:os"
import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"

GraphicsContext :: struct {
	callbackContext:      runtime.Context,
	adapter:              wgpu.Adapter,
	device:               wgpu.Device,
	instance:             wgpu.Instance,
	surface:              wgpu.Surface,
	surfaceConfiguration: wgpu.SurfaceConfiguration,
	pipeline:             wgpu.RenderPipeline,
	pipelineLayout:       wgpu.PipelineLayout,
	shader:               wgpu.ShaderModule,
	queue:                wgpu.Queue,
}

CreateGraphicsContext :: proc(windowHandle: glfw.WindowHandle) -> ^GraphicsContext {
	gc := new(GraphicsContext)
	gc.instance = wgpu.CreateInstance(nil)
	if gc.instance == nil {
		panic("Could not create wgpu instance")
	}

	gc.surface = glfwglue.GetSurface(gc.instance, windowHandle)

	adapterOptions := wgpu.RequestAdapterOptions {
		compatibleSurface = gc.surface,
	}
	requestAdapterCallback := wgpu.RequestAdapterCallbackInfo {
		callback  = on_adapter,
		userdata1 = &gc,
	}

	wgpu.InstanceRequestAdapter(
		gc.instance,
		&{compatibleSurface = gc.surface},
		{callback = on_adapter, userdata1 = gc},
	)

	width, height := glfw.GetFramebufferSize(windowHandle)

	gc.surfaceConfiguration = wgpu.SurfaceConfiguration {
		device      = gc.device,
		usage       = {.RenderAttachment},
		format      = .BGRA8Unorm,
		width       = u32(width),
		height      = u32(height),
		presentMode = .Fifo,
		alphaMode   = .Opaque,
	}

	wgpu.SurfaceConfigure(gc.surface, &gc.surfaceConfiguration)
	gc.queue = wgpu.DeviceGetQueue(gc.device)

	shaderSrc, err := os.read_entire_file_from_path("./shader.wgsl", context.allocator)
	if err != nil {
		log.error("Failed to read file: ", err)
		panic("Failed to read file")
	}

	gc.shader = CreateShader(gc.device, string(shaderSrc))

	gc.pipelineLayout = wgpu.DeviceCreatePipelineLayout(gc.device, &{})
	gc.pipeline = wgpu.DeviceCreateRenderPipeline(
		gc.device,
		&{
			layout = gc.pipelineLayout,
			vertex = {module = gc.shader, entryPoint = "vs_main"},
			fragment = &{
				module      = gc.shader,
				entryPoint  = "fs_main",
				targetCount = 1,
				targets     = &wgpu.ColorTargetState {
					format    = gc.surfaceConfiguration.format, // TODO: Figure out if needs to be the same
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			},
			primitive = {topology = .TriangleList},
			multisample = {count = 1, mask = 0xFFFFFFFF},
		},
	)

	return gc
}

DestroyGraphicsContext :: proc(gc: ^GraphicsContext) {
	wgpu.RenderPipelineRelease(gc.pipeline)
	wgpu.PipelineLayoutRelease(gc.pipelineLayout)
	DestroyShader(gc.shader)
	wgpu.QueueRelease(gc.queue)
	wgpu.DeviceRelease(gc.device)
	wgpu.AdapterRelease(gc.adapter)
	wgpu.SurfaceRelease(gc.surface)
	wgpu.InstanceRelease(gc.instance)
	free(gc)
}

CreateShader :: proc(device: wgpu.Device, src: string) -> wgpu.ShaderModule {
	shaderModuleDescriptor := wgpu.ShaderModuleDescriptor {
		nextInChain = &wgpu.ShaderSourceWGSL{sType = .ShaderSourceWGSL, code = src},
	}
	shaderModule := wgpu.DeviceCreateShaderModule(device, &shaderModuleDescriptor)
	return shaderModule
}

DestroyShader :: proc(shader: wgpu.ShaderModule) {
	wgpu.ShaderModuleRelease(shader)
}

@(private = "file")
on_adapter :: proc "c" (
	status: wgpu.RequestAdapterStatus,
	adapter: wgpu.Adapter,
	message: wgpu.StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	gc := (^GraphicsContext)(userdata1)
	context = gc.callbackContext

	if status != .Success || adapter == nil {
		log.error("request adapter failed: ", status, message)
		panic("Failed to request context")
	}

	gc.adapter = adapter

	wgpu.AdapterRequestDevice(gc.adapter, nil, {callback = on_device, userdata1 = gc})
}

@(private = "file")
on_device :: proc "c" (
	status: wgpu.RequestDeviceStatus,
	device: wgpu.Device,
	message: wgpu.StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	gc := (^GraphicsContext)(userdata1)
	context = gc.callbackContext
	if status != .Success || device == nil {
		log.error("request device failed: ", status, message)
		panic("Device request failed")
	}
	gc.device = device
}
