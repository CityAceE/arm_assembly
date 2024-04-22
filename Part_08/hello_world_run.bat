@set file=hello_world

"c:\Program Files\qemu\qemu-system-arm.exe" -M raspi1ap -serial null -serial stdio -kernel %file%.img
