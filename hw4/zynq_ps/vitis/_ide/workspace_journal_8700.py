# 2026-09-24T23:14:22.094081300
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "zynq_platform",hw_design = "$COMPONENT_LOCATION/../../export/zynq_system.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0",compiler = "gcc")

comp = client.create_app_component(name="led_running_app",platform = "$COMPONENT_LOCATION/../zynq_platform/export/zynq_platform/zynq_platform.xpfm",domain = "standalone_ps7_cortexa9_0")

vitis.dispose()

