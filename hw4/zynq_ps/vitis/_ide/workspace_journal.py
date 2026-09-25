# 2026-09-25T16:57:38.660642800
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.get_component(name="zynq_platform")
status = platform.build()

comp = client.get_component(name="led_running_app")
comp.build()

status = platform.build()

status = platform.build()

comp.build()

comp.build()

comp.build()

vitis.dispose()

vitis.dispose()

