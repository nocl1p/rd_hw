# 2026-09-25T20:10:27.561116600
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "microblaze_platform",hw_design = "$COMPONENT_LOCATION/../../export/microblaze_system.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="microblaze_platform")
status = platform.build()

comp = client.create_app_component(name="running_led_mb",platform = "$COMPONENT_LOCATION/../microblaze_platform/export/microblaze_platform/microblaze_platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="running_led_mb")
comp.build()

vitis.dispose()

