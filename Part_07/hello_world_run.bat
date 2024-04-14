@set file=hello_world

"c:\Program Files\qemu\qemu-system-arm.exe" -M raspi1ap -serial stdio -kernel %file%.img
@rem "c:\Program Files\qemu\qemu-system-arm.exe" -M raspi1ap -kernel %file%.img
