# 2026-10-05T15:39:10.813939
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "hw5_platform",hw_design = "$COMPONENT_LOCATION/../../export/frame_dma.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="hw5_platform")
status = platform.build()

comp = client.create_app_component(name="frame_capture_app",platform = "$COMPONENT_LOCATION/../hw5_platform/export/hw5_platform/hw5_platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="frame_capture_app")
comp.build()

vitis.dispose()

