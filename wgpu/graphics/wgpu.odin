package graphics

import "base:runtime"
import "core:fmt"
import "core:log"
import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"

FRect :: [4]f32
Color :: [4]f32

GraphicsContext :: struct {
	callbackContext:          runtime.Context,
	adapter:                  wgpu.Adapter,
	device:                   wgpu.Device,
	instance:                 wgpu.Instance,
	surface:                  wgpu.Surface,
	surfaceConfiguration:     wgpu.SurfaceConfiguration,
	queue:                    wgpu.Queue,
	coloredRectanglePipeline: ColoredRectanglePipeline,
	activeRenderPass:         Maybe(RenderPass),
}

DrawRectangle :: proc {
	DrawColoredRectangle,
}

CreateGraphicsContext :: proc(windowHandle: glfw.WindowHandle) -> ^GraphicsContext {
	gc := new(GraphicsContext)
	gc.callbackContext = context
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

	gc.coloredRectanglePipeline = CreateColoredRectanglePipeline(gc)

	return gc
}

DestroyGraphicsContext :: proc(gc: ^GraphicsContext) {
	DestroyColoredRectanglePipeline(&gc.coloredRectanglePipeline)
	wgpu.QueueRelease(gc.queue)
	wgpu.DeviceRelease(gc.device)
	wgpu.AdapterRelease(gc.adapter)
	wgpu.SurfaceRelease(gc.surface)
	wgpu.InstanceRelease(gc.instance)
	free(gc)
}

RenderPass :: struct {
	frame:             wgpu.TextureView,
	commandEncoder:    wgpu.CommandEncoder,
	renderPassEncoder: wgpu.RenderPassEncoder,
	surfaceTexture:    wgpu.SurfaceTexture,
}

BeginRenderPass :: proc(gc: ^GraphicsContext, window: glfw.WindowHandle) -> bool {
	rp: RenderPass = {}
	rp.surfaceTexture = wgpu.SurfaceGetCurrentTexture(gc.surface)
	switch rp.surfaceTexture.status {
	case .SuccessOptimal, .SuccessSuboptimal:
	// All good, could handle suboptimal here.
	case .Timeout, .Outdated, .Lost:
		// Skip this frame, and re-configure surface.
		if rp.surfaceTexture.texture != nil {
			wgpu.TextureRelease(rp.surfaceTexture.texture)
		}
		width, height := glfw.GetFramebufferSize(window)
		gc.surfaceConfiguration.width = u32(width)
		gc.surfaceConfiguration.height = u32(height)
		wgpu.SurfaceConfigure(gc.surface, &gc.surfaceConfiguration)
		return false
	case .Occluded:
		// Window is occluded (e.g. minimized), skip this frame.
		return false
	case .Error:
		// Fatal error
		fmt.panicf("[triangle] get_current_texture status=%v", rp.surfaceTexture.status)
	}

	rp.frame = wgpu.TextureCreateView(rp.surfaceTexture.texture, nil)

	rp.commandEncoder = wgpu.DeviceCreateCommandEncoder(gc.device, nil)

	rp.renderPassEncoder = wgpu.CommandEncoderBeginRenderPass(
		rp.commandEncoder,
		&{
			colorAttachmentCount = 1,
			colorAttachments = &wgpu.RenderPassColorAttachment {
				view = rp.frame,
				loadOp = .Clear,
				storeOp = .Store,
				depthSlice = wgpu.DEPTH_SLICE_UNDEFINED,
				clearValue = {0, 1, 0, 1},
			},
		},
	)

	gc.activeRenderPass = rp
	return true
}

EndRenderPass :: proc(gc: ^GraphicsContext) {
	rp, ok := gc.activeRenderPass.?
	if !ok {
		log.error("Tried to end render with no active render pass")
		return
	}
	wgpu.RenderPassEncoderEnd(rp.renderPassEncoder)
	wgpu.RenderPassEncoderRelease(rp.renderPassEncoder)

	commandBuffer := wgpu.CommandEncoderFinish(rp.commandEncoder, nil)
	defer wgpu.CommandBufferRelease(commandBuffer)

	wgpu.QueueSubmit(gc.queue, {commandBuffer})
	wgpu.SurfacePresent(gc.surface)
	wgpu.CommandEncoderRelease(rp.commandEncoder)
	wgpu.TextureViewRelease(rp.frame)
	wgpu.TextureRelease(rp.surfaceTexture.texture)
	gc.activeRenderPass = nil
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

	limits, limits_status := wgpu.AdapterGetLimits(adapter)
	if limits_status != .Success {
		log.error("Failed to get limits")
		panic("Failed to get limits")
	}
	limits.maxImmediateSize = 128
	wgpu.AdapterRequestDevice(
		gc.adapter,
		&wgpu.DeviceDescriptor {
			requiredFeatureCount = 1,
			requiredFeatures = raw_data([]wgpu.FeatureName{.Immediates}),
			requiredLimits = &limits,
		},
		{callback = on_device, userdata1 = gc},
	)
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
